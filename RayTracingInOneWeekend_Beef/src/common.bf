using System.IO;
using System.Text;
using System;

namespace RayTracingInOneWeekend_Beef;

static
{
    typealias COUT = Console;

    public static StreamWriter CLOG = Console.Error;

    struct RedirectToFile : IDisposable
    {
        public this(StringView path)
        {
            FileStream fs = new FileStream();
            if (fs.Create(path, .Write) case .Err)
            {
                return;
            }

            StreamWriter writer = new StreamWriter(fs, Encoding.UTF8, bufferSize: 4096, ownsStream: true);
            writer.AutoFlush = false;

            Console.mOut = writer;
            Console.[Friend]OutputEncoding = Encoding.UTF8;
        }

        public void Dispose()
        {
            Console.mOut.Flush();
        }
    }
}