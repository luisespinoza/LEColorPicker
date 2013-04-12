//
//  ColorFilterShader.fsh
//  LEColorPicker
//
//  Created by Luis Enrique Espinoza Severino on 07-03-13.
//  Copyright (c) 2013 Luis Espinoza. All rights reserved.
//

varying lowp vec4 DestinationColor;
varying lowp vec2 TexCoordOut;
uniform sampler2D Texture;
uniform int ProccesedWidth;
uniform int TotalWidth;
uniform lowp float Tolerance;
uniform lowp vec4 colorToFilter;

void main()
{
    lowp vec4 currentPixel = texture2D(Texture, TexCoordOut);
    highp float currentY = 0.299*currentPixel.r + 0.587*currentPixel.g+ 0.114*currentPixel.b;
    highp float currentU = (-0.14713)*currentPixel.r + (-0.28886)*currentPixel.g + (0.436)*currentPixel.b;
    highp float currentV = 0.615*currentPixel.r + (-0.51499)*currentPixel.g + (-0.10001)*currentPixel.b;
    highp vec3 currentYUV = vec3(currentY,currentU,currentV);
    lowp float d;
    
    if ((TexCoordOut.x > (float(ProccesedWidth)/float(TotalWidth))) || (TexCoordOut.y > (float(ProccesedWidth)/float(TotalWidth)))) {
        gl_FragColor = vec4(0.0,0.0,0.0,1.0); // New
    } else {
        highp float colorToFilterY = 0.299*colorToFilter.r + 0.587*colorToFilter.g+ 0.114*colorToFilter.b;
        highp float colorToFilterU = (-0.14713)*colorToFilter.r + (-0.28886)*colorToFilter.g + (0.436)*colorToFilter.b;
        highp float colorToFilterV = 0.615*colorToFilter.r + (-0.51499)*colorToFilter.g + (-0.10001)*colorToFilter.b;
        highp vec3 colorToFilterYUV = vec3(colorToFilterY,colorToFilterU,colorToFilterV);
        
        d = distance(colorToFilterYUV,currentYUV);
        lowp float alpha;
        if (d < 0.2) {
            alpha = 0.0;
        } else {
            alpha = 1.0;
        }
        gl_FragColor = vec4(currentPixel.r,currentPixel.g,currentPixel.b,alpha); // New
    }
}
