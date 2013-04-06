//
//  DominantColorShader.fsh
//  LEColorPicker
//
//  Created by Luis Enrique Espinoza Severino on 07-03-13.
//  Copyright (c) 2013 Luis Espinoza. All rights reserved.
//

varying lowp vec4 DestinationColor;
varying lowp vec2 TexCoordOut; // New
uniform sampler2D Texture; // New

void main(void) {
    lowp float accumulator = 0.0;
    lowp vec4 currentPixel = texture2D(Texture, TexCoordOut);
    
    highp float currentY = 0.299*currentPixel.r + 0.587*currentPixel.g+ 0.114*currentPixel.b;
    highp float currentU = (-0.14713)*currentPixel.r + (-0.28886)*currentPixel.g + (0.436)*currentPixel.b;
    highp float currentV = 0.615*currentPixel.r + (-0.51499)*currentPixel.g + (-0.10001)*currentPixel.b;
    highp vec3 currentYUV = vec3(currentY,currentU,currentV);
    lowp float d;
    if ((TexCoordOut.x > 0.5) || (TexCoordOut.y > 0.5)) {
        gl_FragColor = vec4(0.0,0.0,0.0,1.0); // New
    } else {
        accumulator = 0.0;
        for (int i=0; i<16; i=i+1) {
            for (int j=0; j<16; j=j+1) {
                lowp vec2 coord = vec2(float(i)/16.0,float(j)/16.0);
                lowp vec4 samplePixel = texture2D(Texture, coord);
                //lowp float sampleRed = samplePixel.r;
                //lowp float sampleGreen = samplePixel.g;
                //lowp float sampleBlue = samplePixel.b;
                
                highp float sampleY = 0.299*samplePixel.r + 0.587*samplePixel.g+ 0.114*samplePixel.b;
                highp float sampleU = (-0.14713)*samplePixel.r + (-0.28886)*samplePixel.g + (0.436)*samplePixel.b;
                highp float sampleV = 0.615*samplePixel.r + (-0.51499)*samplePixel.g + (-0.10001)*samplePixel.b;
                highp vec3 sampleYUV = vec3(sampleY,sampleU,sampleV);
                
                d = distance(sampleYUV,currentYUV);
                
                if (d < 0.1) {
                    //                    if (accumulatorR <1.0) {
                    //                        accumulatorR = accumulatorR + 1.0/100.0;
                    //                    } else {
                    //                        if (accumulatorG < 1.0) {
                    //                            accumulatorG = accumulatorG + 1.0/100.0;
                    //                        } else {
                    //                            accumulatorB = accumulatorB + 1.0/100.0;
                    //                        }
                    //                    }
                    accumulator = accumulator + 0.0039;
                }
            }
        }
        gl_FragColor = vec4(accumulator,0.0,0.0,1.0); // New
    }
}