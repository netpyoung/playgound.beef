using System;
using System.Diagnostics;

namespace PixelHorizon_Beef.ImageData;

[Packed(4)]
struct PIXEL_STREAM
{
    public uint16 wPosX;
    public uint16 wPixelNum;
    public uint32 dwPixel;
}

struct COMPRESSED_LINE
{
    public uint32 dwStreamNum;
    public uint32 dwLineDataSize;

    [Union]
    public struct
    {
        public PIXEL_STREAM* pPixelStream;
        public uint32 dwOffset;
    };
}

class ImageData
{
    uint32 m_dwWidth = 0;
    uint32 m_dwHeight = 0;
    COMPRESSED_LINE[] m_pCompressedImage = null;

    // TODO(pyoung): getter/setter
    public uint32 GetWidth() { return m_dwWidth; }
    public uint32 GetHeight() { return m_dwHeight; }

    public ~this()
    {
        DeleteAndNullify!(m_pCompressedImage);
    }

    public bool Create(uint8[] pSrcBits, uint32 dwWidth, uint32 dwHeight, uint32 dwColorKey)
    {
        uint dwWorkingMemSize = sizeof(PIXEL_STREAM) * dwWidth * dwHeight;

        uint8[] pWorkingMemory = new uint8[dwWorkingMemSize];
        defer delete pWorkingMemory;

        COMPRESSED_LINE[] pLineList = new COMPRESSED_LINE[dwHeight];
        defer delete pLineList;

        uint8* pSrcEntry = pSrcBits.Ptr;
        uint8* pDestEntry = pWorkingMemory.Ptr;
        uint32 dwUsedMemSize = 0;
        for (int i = 0; i < dwHeight; i++)
        {
            uint32 dwStreamNumPerLine = CreatePerLine(pDestEntry, dwWorkingMemSize, (uint32*)pSrcEntry, dwWidth, dwColorKey);

            uint32 dwLineMemSize = sizeof(PIXEL_STREAM) * dwStreamNumPerLine;
            pSrcEntry += (dwWidth * 4);

            uint32 dwOffset = (uint32)(pDestEntry - pWorkingMemory.Ptr);
            if ((int)dwWorkingMemSize - (int)dwLineMemSize < 0)
            {
                Debug.Break();
            }

            dwWorkingMemSize -= dwLineMemSize;
            dwUsedMemSize += dwLineMemSize;
            pDestEntry += dwLineMemSize;
            pLineList[i].dwLineDataSize = dwLineMemSize;
            pLineList[i].dwStreamNum = dwStreamNumPerLine;
            pLineList[i].dwOffset = dwOffset;
        }

        // 수집한 픽셀 스트림과 각 라인의 디스크립터가 되는 COMPRESSED_LINE메모리를 한번에 할당한다.
        dwUsedMemSize += sizeof(COMPRESSED_LINE) * dwHeight;

        // m_pCompressedImage = (COMPRESSED_LINE*)malloc(dwUsedMemSize);
        m_pCompressedImage = new COMPRESSED_LINE[dwUsedMemSize / sizeof(COMPRESSED_LINE)]; // TODO(pyoung): remove sizeof(COMPRESSED_LINE)

        uint8* pPixelStreamDataEntry = (uint8*)m_pCompressedImage.Ptr + sizeof(COMPRESSED_LINE) * dwHeight;

        for (int i = 0; i < dwHeight; i++)
        {
            uint8* pSrcPixelStreamData = pWorkingMemory.Ptr + pLineList[i].dwOffset; // 앞서 수집한 픽셀 스트림이 저장된 메모리
            pLineList[i].pPixelStream = (PIXEL_STREAM*)pPixelStreamDataEntry; // 써넣을 메모리
            Internal.MemCpy(pPixelStreamDataEntry, pSrcPixelStreamData, pLineList[i].dwLineDataSize); // 수집한 픽셀 스트림을 확정된 메모리로 카피.
            pPixelStreamDataEntry += pLineList[i].dwLineDataSize;
        }
        Internal.MemCpy(m_pCompressedImage.Ptr, pLineList.Ptr, sizeof(COMPRESSED_LINE) * dwHeight);

        m_dwWidth = dwWidth;
        m_dwHeight = dwHeight;

        return true;
    }

    uint32 CreatePerLine(uint8* pDest, uint iMaxMemSize, uint32* pSrcBits, uint32 dwWidth, uint32 dwColorKey)
    {
        uint iMaxMemSizeTrack = iMaxMemSize;
        PIXEL_STREAM* pStreamList = (PIXEL_STREAM*)pDest;
        uint32 dwStreamCount = 0;

        uint32 x = 0;
        while (x < dwWidth)
        {
            // 컬러키가 아닌 픽셀을 만날때까지 x축으로 진행
            while (pSrcBits[x] == dwColorKey)
            {
                x++;
                if (x >= dwWidth)
                {
                    return dwStreamCount;
                }
            }

            uint32 dwCurPixel = pSrcBits[x];

            if (iMaxMemSizeTrack - sizeof(PIXEL_STREAM) < 0)
            {
                Debug.Break();
            }

            pStreamList[dwStreamCount].wPosX = (uint16)x;
            pStreamList[dwStreamCount].dwPixel = dwCurPixel;
            iMaxMemSizeTrack -= sizeof(PIXEL_STREAM);

            // 현재 픽셀과 다른 픽셀(컬러키 포함)을 만날때까지 진행
            while (x < dwWidth && pSrcBits[x] == dwCurPixel)
            {
                pStreamList[dwStreamCount].wPixelNum++;
                x++;
            }
            dwStreamCount++;
        }


        return dwStreamCount;
    }

    public COMPRESSED_LINE* GetCompressedImage(int32 y)
    {
        Debug.Assert(y >= 0);
        Debug.Assert(y < (int32)m_dwHeight);

        return m_pCompressedImage.Ptr + y;
    }
}
