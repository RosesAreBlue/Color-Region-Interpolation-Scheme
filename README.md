# Color-Region-Interpolation-Scheme
Application of inverse distance weighting in a discrete setting.

The original problem I came up against was trying to interpolate smoothly between different color regions on an image efficiently.
This was my original solution.

Some results:

![RobloxStudioBeta_2020-05-14_20-15-22](https://user-images.githubusercontent.com/33347703/81976505-8ef8a080-9620-11ea-9aa4-99eb44a16deb.png)
![RobloxStudioBeta_2020-05-14_20-15-39](https://user-images.githubusercontent.com/33347703/81976508-9029cd80-9620-11ea-995b-aeff716a9c29.png)

(One other cool application of the same method: easy terrain generation.)
![ezgif-2-7c0151ae7ee8](https://user-images.githubusercontent.com/33347703/81977449-f2370280-9621-11ea-9f30-211ce75c7e14.gif)
https://www.geogebra.org/m/fvs6uvft

# The Algorithm

First, I collect all pixels of the same (or similar enough) color in a lookup table.
Next, I treat each pixel as a "source" where color can flood out from.

![Untitled](https://user-images.githubusercontent.com/33347703/81981891-d6832a80-9628-11ea-9ca1-ec021496d0d9.png)

Next, we flood fill outwards from the boundary of each color region making a mark of the iterations it took to get to each pixel. We treat the iteration count as pseudo-distance from the boundary. https://en.wikipedia.org/wiki/Flood_fill
![Untitled3](https://user-images.githubusercontent.com/33347703/81981886-d551fd80-9628-11ea-9255-301b98d53092.png)

Eventually, the distances from blue, and the distances from red overlap and we store their ratio.
![Untitled4](https://user-images.githubusercontent.com/33347703/81981893-d6832a80-9628-11ea-921b-a68836213acd.png)

Next,
