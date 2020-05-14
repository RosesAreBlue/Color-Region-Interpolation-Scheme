# Color-Region-Interpolation-Scheme
The original problem I came up against was trying to interpolate smoothly between different color regions on an image efficiently.
This was my original solution. Here I apply inverse distance weighting in a discrete setting.
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

Next, we now know that the pixel near the centre is "5-away" from the red border and "6-away" from the blue border.
Therefore, we need to pick a color such that the closer border has more influence.

To do this:
```
Let the left part of the ratio represent red influence, and right, blue inluence.
We want a weighted average of both channels such that red has more influence.
So take the ratio        
5:6
We want more red influence, so take the inverse of both sides
1/5 : 1/6     (Note the left side is now bigger than the right)
Finally, make the ratios add up to 1 so that we may use it in a weighted average.
1/5 + 1/6 = 11/30
So,
1/5 ÷ 11/30 : 1/6 ÷ 11/30
6/11 : 5/11
Hence, we have our weighted average.
```

We now do ``6/11*RedChannel + 5/11*BlueChannel`` to produce the new color below.

![FinalUntitled](https://user-images.githubusercontent.com/33347703/81982529-e3ece480-9629-11ea-9ef8-c7397939b114.png)

This is then repeated for every pixel until you get something like this,

