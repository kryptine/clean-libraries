system module xpicture;

StartXDrawing :: !Int -> Int;
EndXDrawing :: !Int -> Int;
HidePenX :: !Int -> Int;
ShowPenX :: !Int -> Int;
GetPenX :: !Int -> (!Int,!Int);
PenSizeX :: !Int !Int !Int -> Int;
PenModeX :: !Int !Int -> Int;
PenPatternX :: !Int !Int -> Int;
PenNormalX :: !Int -> Int;
MoveToX :: !Int !Int !Int -> Int;
MoveRelativeX :: !Int !Int !Int -> Int;
LineToX :: !Int !Int !Int -> Int;
LineRelativeX :: !Int !Int !Int -> Int;
DrawStringX :: !{#Char} !Int -> Int;
GetColorX :: !Int -> Int;
ForegroundColorX :: !Int !Int -> Int;
BackgroundColorX :: !Int !Int -> Int;
RGBForegroundColorX :: !Real !Real !Real !Int -> Int;
RGBBackgroundColorX :: !Real !Real !Real !Int -> Int;
DrawLineX :: !Int !Int !Int !Int !Int -> Int;
DrawPointX :: !Int !Int !Int -> Int;
FrameRectangleX :: !Int !Int !Int !Int !Int -> Int;
PaintRectangleX :: !Int !Int !Int !Int !Int -> Int;
EraseRectangleX :: !Int !Int !Int !Int !Int -> Int;
InvertRectangleX :: !Int !Int !Int !Int !Int -> Int;
MoveRectangleX :: !Int !Int !Int !Int !Int !Int !Int -> Int;
CopyRectangleX :: !Int !Int !Int !Int !Int !Int !Int -> Int;
FrameRoundRectangleX :: !Int !Int !Int !Int !Int !Int !Int -> Int;
PaintRoundRectangleX :: !Int !Int !Int !Int !Int !Int !Int -> Int;
EraseRoundRectangleX :: !Int !Int !Int !Int !Int !Int !Int -> Int;
InvertRoundRectangleX :: !Int !Int !Int !Int !Int !Int !Int -> Int;
FrameOvalX :: !Int !Int !Int !Int !Int -> Int;
PaintOvalX :: !Int !Int !Int !Int !Int -> Int;
EraseOvalX :: !Int !Int !Int !Int !Int -> Int;
InvertOvalX :: !Int !Int !Int !Int !Int -> Int;
FrameArcX :: !Int !Int !Int !Int !Int !Int !Int -> Int;
PaintArcX :: !Int !Int !Int !Int !Int !Int !Int -> Int;
EraseArcX :: !Int !Int !Int !Int !Int !Int !Int -> Int;
InvertArcX :: !Int !Int !Int !Int !Int !Int !Int -> Int;
AllocatePolygonX :: !Int -> Int;
FreePolygonX :: !Int !Int -> Int;
SetPolygonPointX :: !Int !Int !Int !Int -> Int;
FramePolygonX :: !Int !Int !Int !Int !Int -> Int;
PaintPolygonX :: !Int !Int !Int !Int !Int -> Int;
ErasePolygonX :: !Int !Int !Int !Int !Int -> Int;
InvertPolygonX :: !Int !Int !Int !Int !Int -> Int;
GetNumberOfFontsX :: !Int -> Int;
GetFontNameX :: !Int -> {#Char};
GetFontInfoX :: !Int -> (!Int,!Int,!Int,!Int,!Int);
GetFontFontInfoX :: !Int -> (!Int,!Int,!Int,!Int);
GetStringWidthX :: !Int !{#Char} -> (!Int,!Int);
GetFontStringWidthX :: !Int !{#Char} -> Int;
SetFontX :: !Int !Int !{#Char} !{#Char} !{#Char} -> Int;
SetFontNameX :: !Int !{#Char} -> Int;
SetStyleX :: !Int !{#Char} -> Int;
SetSizeX :: !Int !{#Char} -> Int;
SelectDefaultFontX :: !Int -> Int;
SelectFontX :: !{#Char} -> Int;
GetFontStylesX :: !{#Char} -> (!Int,!Int,!Int,!Int,!Int);
GetFontSizesX :: !{#Char} -> Int;
GetOneFontSizeX :: !Int -> Int;
