using System;
using System.Diagnostics;
using System.IO;

namespace PixelHorizon_Beef.Utils;

[Packed(1), Ordered]
struct TGA_HEADER
{
    public uint8 idLength;
    public uint8 ColorMapType;
    public uint8 ImageType;
    public uint16 ColorMapFirst;
    public uint16 ColorMapLast;
    public uint8 ColorMapBits;
    public uint16 FirstX;
    public uint16 FirstY;
    public uint16 width;
    public uint16 height;
    public uint8 Bits;
    public uint8 Descriptor;
}

class TGAImage
{
    uint32 m_dwWidth;
    uint32 m_dwHeight;
    uint8[] m_pRawImage;
    uint32 m_dwBytePerPixel;

    public uint8[] GetRawImage()
    {
        return m_pRawImage;
    }

    public uint32 GetWidth()
    {
        return m_dwWidth;
    }

    public uint32 GetHeight()
    {
        return m_dwHeight;
    }

    public ~this()
    {
        Destroy();
    }

    void Destroy()
    {
        DeleteAndNullify!(m_pRawImage);
    }

    public static bool WriteTGA(StringView szFileName, uint8* pSrc, uint32 dwWidth, uint32 dwHeight, uint32 dwPitch, uint32 bpp)
    {
        UnbufferedFileStream fs = scope UnbufferedFileStream();
        if (fs.Open(szFileName, .Create, .Write) case .Err(let err))
        {
            Console.Error.WriteLine($"err: {err}");
            return false;
        }

        WriteTGAImage(fs, pSrc, dwWidth, dwHeight, dwPitch, bpp);
        return true;
    }

    public static int64 WriteTGAImage(UnbufferedFileStream fs, uint8* pSrc, uint32 dwWidth, uint32 dwHeight, uint32 dwPitch, uint32 bpp)
    {
        int64 dwOldPos = fs.Position;

        TGA_HEADER	header = .();
        header.width = (uint16)dwWidth;
        header.height = (uint16)dwHeight;
        header.Bits = 24;
        header.ImageType = 2;

        if (fs.TryWrite(.((uint8*)&header, sizeof(TGA_HEADER))) case .Err)
        {
            return 0;
        }

        uint32	dwSize = dwWidth * dwHeight * 3;
        uint8[] pBits = new uint8[dwSize];
        defer delete pBits;

        uint8* pDest = pBits.Ptr;

        if (bpp == 16)
        {
            for (int y = (int)dwHeight - 1; y >= 0; y--)
            {
                for (int x = 0; x < (int)dwWidth; x++)
                {
                    uint16 wPixel = *(uint16*)(pSrc + (x << 1) + dwPitch * y);
                    uint8 r = (uint8)((wPixel & 0x001F) << 3);
                    uint8 g = (uint8)((wPixel & 0x07E0) >> 5 << 2);
                    uint8 b = (uint8)((wPixel & 0xF800) >> 11 << 3);

                    *(pDest + 0) = r;
                    *(pDest + 1) = g;
                    *(pDest + 2) = b;
                    /*
                    fwrite(&r,1,1,fp);
                    fwrite(&g,1,1,fp);
                    fwrite(&b,1,1,fp);
                    */

                    pDest += 3;
                }
            }
        }
        else if (bpp == 32)
        {
            for (int y = (int)dwHeight - 1; y >= 0; y--)
            {
                for (int x = 0; x < (int)dwWidth; x++)
                {
                    *(pDest + 0) = *((pSrc + (x << 2) + dwPitch * y) + 0);
                    *(pDest + 1) = *((pSrc + (x << 2) + dwPitch * y) + 1);
                    *(pDest + 2) = *((pSrc + (x << 2) + dwPitch * y) + 2);

                    pDest += 3;
                }
            }
        }
        else if (bpp == 24)
        {
            for (int y = (int)dwHeight - 1; y >= 0; y--)
            {
                for (int x = 0; x < (int)dwWidth; x++)
                {
                    *(pDest + 0) = *((pSrc + (x * 3) + dwPitch * y) + 0);
                    *(pDest + 1) = *((pSrc + (x * 3) + dwPitch * y) + 1);
                    *(pDest + 2) = *((pSrc + (x * 3) + dwPitch * y) + 2);

                    pDest += 3;
                }
            }
        }

        if (fs.TryWrite(.(pBits, dwSize)) case .Err)
        {
            return 0;
        }

        return fs.Position - dwOldPos;
    }


    public bool Load24BitsTGA(StringView szFileName, uint32 dwBytesPerPixel)
    {
        UnbufferedFileStream fs = scope UnbufferedFileStream();
        if (fs.Open(szFileName, .Open, .Read, .ReadWrite) case .Err(let err))
        {
            Console.Error.WriteLine($"fs.Open : {err}");
            return false;
        }

        bool bResult = LoadTGAImage(fs, dwBytesPerPixel);
        return bResult;
    }

    static bool FsRead<T>(UnbufferedFileStream fs, ref T v) where T : struct
    {
        Span<uint8> s = Span<uint8>((uint8*)&v, sizeof(T));
        return FsRead(fs, s);
    }

    static bool FsRead(UnbufferedFileStream fs, Span<uint8> s)
    {
        uint8[8192] buffer = ?;

        int needToReadLength = s.Length;
        int offset = 0;
        while (true)
        {
            int shouldBuffReadLength = Math.Min(needToReadLength, buffer.Count);
            switch (fs.TryRead(.(&buffer, shouldBuffReadLength)))
            {
            case .Ok(let bytes):
                if (bytes == 0)
                {
                    Debug.Assert(needToReadLength == 0);
                    return true;
                }

                Internal.MemCpy(s.Ptr + offset, &buffer, bytes);
                offset += bytes;
                needToReadLength -= bytes;
                Debug.Assert(needToReadLength >= 0);
                if (needToReadLength == 0)
                {
                    return true;
                }
            case .Err:
                return false;
            }
        }
    }

    bool LoadTGAImage(UnbufferedFileStream fs, uint32 dwBytesPerPixel)
    {
        Destroy();

        TGA_HEADER header = .();
        if (!FsRead(fs, ref header))
        {
            return false;
        }

        /*
        // 이미지 타잎이 이 중 하나가 아니라면 이 파일은 로드할 수 없다.
        if (ImageType!=0x01 &&
            ImageType!=0x02 &&
            ImageType!=0x03 &&
            ImageType!=0x09 &&
            ImageType!=0x0A &&
            ImageType!=0x0B)
        {
            fclose(fp);
            return FALSE;
        }*/

        uint8[] temp = new uint8[4 * header.width * header.height];
        defer delete temp;

        Internal.MemSet(temp.Ptr, 0, temp.Count);

        uint32 dwSize = 3 * header.width * header.height;
        if (!FsRead(fs, .(temp.Ptr, dwSize)))
        {
            return false;
        }

        uint32 dwWidthBytes;
        uint32 x = 0;
        uint32 y = 0;
        uint32 line = header.height;

        m_pRawImage = new uint8[4 * header.width * header.height]; // 이미지를 위한 메모리할당

        if (dwBytesPerPixel == 2)
        {
            dwWidthBytes = header.width * 2;
            m_dwBytePerPixel = 2;


            for (y = 0; y < header.height; y++)
            {
                line--;
                for (x = 0; x < header.width; x++)
                {
                    *(uint16*)(m_pRawImage.Ptr + line * header.width * 2 + x * 2) =
                        temp[y * header.width * 3 + x * 3 + 0] >> 3 |
                        temp[y * header.width * 3 + x * 3 + 1] >> 2 << 5 |
                        (uint16)temp[y * header.width * 3 + x * 3 + 2] >> 3 << 11;
                }
            }
            /*
            if (header.Descriptor)
            {

            }
            else
            {
                for (y=0; y<header.height; y++)
                {
                    for (x=0; x<header.width; x++)
                    {
                        *(WORD*)(m_pRawImage+y*header.width*2+x*2) =
                            temp[y*header.width*3+x*3+0]>>3 |
                            temp[y*header.width*3+x*3+1]>>2<<5 |
                            temp[y*header.width*3+x*3+2]>>3<<11;

                    }
                }
            }*/
        }
        else if (dwBytesPerPixel == 4)
        {
            m_dwBytePerPixel = 4;
            dwWidthBytes = header.width * 4;

            for (y = 0; y < header.height; y++)
            {
                line--;
                for (x = 0; x < header.width; x++)
                {
                    m_pRawImage[line * dwWidthBytes + x * 4 + 0] = temp[y * header.width * 3 + x * 3 + 0];
                    m_pRawImage[line * dwWidthBytes + x * 4 + 1] = temp[y * header.width * 3 + x * 3 + 1];
                    m_pRawImage[line * dwWidthBytes + x * 4 + 2] = temp[y * header.width * 3 + x * 3 + 2];
                    m_pRawImage[line * dwWidthBytes + x * 4 + 3] = 255;
                }
            }
            /*
            if (header.Descriptor)
            {

            }
            else
            {
                for (y=0; y<header.height; y++)
                {
                    for (x=0; x<header.width; x++)
                    {
                        m_pRawImage[y*dwWidthBytes + x*4+0] = temp[y*header.width*3+x*3+0];
                        m_pRawImage[y*dwWidthBytes + x*4+1] = temp[y*header.width*3+x*3+1];
                        m_pRawImage[y*dwWidthBytes + x*4+2] = temp[y*header.width*3+x*3+2];
                        m_pRawImage[y*dwWidthBytes + x*4+3] = (BYTE)255;

                    }
                }
            }*/
        }

        m_dwWidth = header.width;
        m_dwHeight = header.height;

        return true;
    }


    uint32 Blt(
        uint8* pDestBits,
        int iDestX, int iDestY,
        uint32 dwScreenWidth, uint32 dwScreenHeight,
        uint32 dwPitch, uint32 dwBytePerPixel,
        int iSrcStartX, int iSrcStartY, int iSrcWidth, int iSrcHeight)
    {
        if (m_pRawImage == null)
        {
            return 0;
        }

        if (dwBytePerPixel != m_dwBytePerPixel)
        {
            Debug.Break();
            return 0;
        }

        //int iScreenStartX = iDestX;
        int iScreenEndX = (int)dwScreenWidth - 1;

        //int iScreenStartY = iDestY;
        int iScreenEndY = (int)dwScreenHeight - 1;

        int srcStartX = iSrcStartX;
        int srcStartY = iSrcStartY;
        int srcWidth = iSrcWidth;
        int srcHeight = iSrcHeight;

        // dest
        // 수평 클리핑
        int dest_start_x = iDestX;
        int dest_end_x = iDestX + srcWidth - 1;
        if (dest_start_x > iScreenEndX)
        {
            return 0;
        }

        if (dest_end_x < 0)
        {
            return 0;
        }

        if (dest_start_x < 0)
        {
            srcWidth += dest_start_x;
            srcStartX -= dest_start_x;
            dest_start_x = 0;
        }

        int	iMargine = iScreenEndX - dest_end_x;
        if (iMargine < 0)
        {
            srcWidth += iMargine;
        }

        // 수직 클리핑
        int dest_start_y = iDestY;
        int dest_end_y = iDestY + srcHeight - 1;
        if (dest_start_y > iScreenEndY)
        {
            return 0;
        }

        if (dest_end_y < 0)
        {
            return 0;
        }

        if (dest_start_y < 0)
        {
            srcHeight += dest_start_y;
            srcStartY -= dest_start_y;
            dest_start_y = 0;
        }

        iMargine = iScreenEndY - dest_end_y;
        if (iMargine < 0)
        {
            srcHeight += iMargine;
        }

        uint32 dwSrcPitch = m_dwWidth * m_dwBytePerPixel;
        uint8* pSrc = m_pRawImage.Ptr + (srcStartX * m_dwBytePerPixel) + (srcStartY * dwSrcPitch);
        uint8* pDest = pDestBits + (dest_start_x * dwBytePerPixel) + (dest_start_y * dwPitch);

        uint32 dwPixelNum = 0;
        for (int y = 0; y < srcHeight; y++)
        {
            Internal.MemCpy(pDest, pSrc, srcWidth * dwBytePerPixel);
            pSrc += dwSrcPitch;
            pDest += dwPitch;
            dwPixelNum += (uint32)srcWidth;
        }

        return dwPixelNum;
    }

    public uint32 GetPixel(uint32 x, uint32 y)
    {
        uint32 dwColor = *(uint32*)(m_pRawImage.Ptr + ((x + y * m_dwWidth) * 4));
        return dwColor;
    }

}