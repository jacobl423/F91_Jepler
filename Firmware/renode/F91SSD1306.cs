// Project-local SSD1306 I2C model for Zephyr's page-packed monochrome framebuffer.
// Supports addressing, orientation, inversion, blanking and panel offset.
// Analog timing, charge pump, contrast and hardware scrolling are not simulated.
using System;
using System.IO;
using Antmicro.Renode.Core;
using Antmicro.Renode.Backends.Display;
using Antmicro.Renode.Peripherals.I2C;
using Antmicro.Renode.Logging;

namespace Antmicro.Renode.Peripherals.Video
{
    public class F91SSD1306 : AutoRepaintingVideo, II2CPeripheral
    {
        public F91SSD1306(IMachine machine, int width = 96, int height = 40) : base(machine)
        {
            if(width < 1 || width > 128 || height < 1 || height > 64)
                throw new ArgumentOutOfRangeException("Invalid SSD1306 panel dimensions");
            Reconfigure(width, height, PixelFormat.RGB888);
            Reset();
        }

        public override void Reset()
        {
            Array.Clear(ram, 0, ram.Length);
            column = page = columnStart = pageStart = 0;
            columnEnd = 127; pageEnd = 7; addressing = 2;
            pending = remaining = argumentIndex = 0;
            startLine = offset = 0; multiplex = Height;
            enabled = inverted = entireDisplay = segmentRemap = comReverse = false;
            DataBytesWritten = 0;
            FinishTransmission();
            Repaint();
        }

        public void Write(byte[] data)
        {
            foreach(var value in data)
            {
                if(expectControl)
                {
                    isData = (value & 0x40) != 0;
                    continuation = (value & 0x80) != 0;
                    expectControl = false;
                    continue;
                }
                if(isData) WritePixelByte(value); else Command(value);
                if(continuation) expectControl = true;
            }
        }

        public byte[] Read(int count = 1) { return new byte[count]; }
        public void FinishTransmission() { expectControl = true; }
        public long DataBytesWritten { get; private set; }
        public bool DisplayEnabled { get { return enabled; } }
        public int LitPixels
        {
            get
            {
                Repaint();
                int count = 0;
                for(int i = 0; i < buffer.Length; i += 3) if(buffer[i] != 0) count++;
                return count;
            }
        }

        // Portable snapshot for headless checks; contains the actual emulated pixels.
        public void SaveFrame(string path)
        {
            Repaint();
            using(var output = File.Create(path))
            {
                var header = System.Text.Encoding.ASCII.GetBytes("P6\n" + Width + " " + Height + "\n255\n");
                output.Write(header, 0, header.Length);
                output.Write(buffer, 0, buffer.Length);
            }
        }

        protected override void Repaint()
        {
            for(int y = 0; y < Height; y++)
            for(int x = 0; x < Width; x++)
            {
                // The virtual module's glass wiring is A1/C8 (normal Zephyr orientation).
                int sx = segmentRemap ? x : Width - 1 - x;
                int sy = comReverse ? y : multiplex - 1 - y;
                sy = (sy + startLine - offset + 64) & 63;
                bool bit = (ram[(sy / 8) * 128 + sx] & (1 << (sy & 7))) != 0;
                bool lit = enabled && y < multiplex && (entireDisplay || (bit ^ inverted));
                int index = (y * Width + x) * 3;
                buffer[index] = buffer[index + 1] = buffer[index + 2] = lit ? (byte)255 : (byte)0;
            }
        }

        private void WritePixelByte(byte value)
        {
            ram[page * 128 + column] = value;
            DataBytesWritten++;
            if(addressing == 1)
            {
                if(++page > pageEnd) { page = pageStart; if(++column > columnEnd) column = columnStart; }
            }
            else if(addressing == 0)
            {
                if(++column > columnEnd) { column = columnStart; if(++page > pageEnd) page = pageStart; }
            }
            else column = (column + 1) & 127;
        }

        private void Command(byte value)
        {
            if(remaining > 0)
            {
                args[argumentIndex++] = value;
                if(--remaining != 0) return;
                switch(pending)
                {
                    case 0x20: addressing = args[0] & 3; break;
                    case 0x21: column = columnStart = args[0] & 127; columnEnd = args[1] & 127; break;
                    case 0x22: page = pageStart = args[0] & 7; pageEnd = args[1] & 7; break;
                    case 0xA8: multiplex = (args[0] & 63) + 1; break;
                    case 0xD3: offset = args[0] & 63; break;
                }
                return;
            }
            if(value <= 0x0F) { column = (column & 0x70) | value; return; }
            if(value <= 0x1F) { column = (column & 0x0F) | ((value & 7) << 4); return; }
            if(value >= 0x40 && value <= 0x7F) { startLine = value & 63; return; }
            if(value >= 0xB0 && value <= 0xB7) { page = value & 7; return; }
            switch(value)
            {
                case 0x20: case 0x81: case 0x8D: case 0xA8: case 0xAD:
                case 0xD3: case 0xD5: case 0xD9: case 0xDA: case 0xDB:
                    remaining = 1; break;
                case 0x21: case 0x22: remaining = 2; break;
                case 0xAE: enabled = false; break;
                case 0xAF: enabled = true; break;
                case 0xA0: segmentRemap = false; break;
                case 0xA1: segmentRemap = true; break;
                case 0xC0: comReverse = false; break;
                case 0xC8: comReverse = true; break;
                case 0xA4: entireDisplay = false; break;
                case 0xA5: entireDisplay = true; break;
                case 0xA6: inverted = false; break;
                case 0xA7: inverted = true; break;
                case 0xE4: Reset(); break;
                case 0x2E: break; // Scrolling disabled.
                case 0x30: case 0x31: case 0x32: case 0x33: break; // Pump voltage.
                default: this.Log(LogLevel.Warning, "Unsupported SSD1306 command 0x{0:X2}", value); break;
            }
            pending = value; argumentIndex = 0;
        }

        private readonly byte[] ram = new byte[128 * 8];
        private readonly byte[] args = new byte[2];
        private int column, page, columnStart, columnEnd, pageStart, pageEnd, addressing;
        private int pending, remaining, argumentIndex, startLine, offset, multiplex;
        private bool enabled, inverted, entireDisplay, segmentRemap, comReverse;
        private bool expectControl, isData, continuation;
    }
}
