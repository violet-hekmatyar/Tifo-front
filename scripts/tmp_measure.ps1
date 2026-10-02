$code = @'
using System;
using System.Drawing;
public class ImgMeasure {
  public static void Run(string path) {
    using (var b = new Bitmap(path)) {
      int w = b.Width, h = b.Height;
      bool[] row = new bool[h];
      bool[] col = new bool[w];
      for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) {
        var c = b.GetPixel(x, y);
        if (c.G > 120 && c.G > c.R * 1.25 && c.G > c.B * 1.05) { row[y] = true; col[x] = true; }
      }
      int minx = w, maxx = -1, miny = h, maxy = -1;
      for (int x = 0; x < w; x++) if (col[x]) { minx = Math.Min(minx, x); maxx = Math.Max(maxx, x); }
      for (int y = 0; y < h; y++) if (row[y]) { miny = Math.Min(miny, y); maxy = Math.Max(maxy, y); }
      Console.WriteLine(path + ": green bbox " + minx + "," + miny + ".." + maxx + "," + maxy);
      for (int y = 0; y < h; y++) {
        if (!row[y]) continue;
        int ys = y;
        while (y + 1 < h && row[y + 1]) y++;
        Console.WriteLine("run " + ys + ".." + y);
      }
    }
  }
}
'@
Add-Type -TypeDefinition $code -ReferencedAssemblies System.Drawing
[ImgMeasure]::Run('C:\Users\hekmatyar\Desktop\足球APP\其他空状态图标.png')
[ImgMeasure]::Run('D:\Football-APP-Front\apps\mobile\test\shared\widgets\goldens\vr13_catalog.png')
