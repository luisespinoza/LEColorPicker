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

highp vec4 encode32(highp float f) {
    highp float e =5.0;
    
    highp float F = abs(f);
    highp float Sign = step(0.0,-f);
    highp float Exponent = floor(log2(F));
    highp float Mantissa = (exp2(- Exponent) * F);
    Exponent = floor(log2(F) + 127.0) + floor(log2(Mantissa));
    highp vec4 rgba;
    rgba[0] = 128.0 * Sign  + floor(Exponent*exp2(-1.0));
    rgba[1] = 128.0 * mod(Exponent,2.0) + mod(floor(Mantissa*128.0),128.0);
    rgba[2] = floor(mod(floor(Mantissa*exp2(23.0 -8.0)),exp2(8.0)));
    rgba[3] = floor(exp2(23.0)*mod(Mantissa,exp2(-15.0)));
    return rgba;
}

void main(void) {
    
    int accumulatorR = 0;
    int accumulatorG = 0;
    int accumulatorB = 0;
    
    lowp vec4 currentPixel = texture2D(Texture, TexCoordOut);
    lowp float currentRed = currentPixel.r;
    lowp float currentGreen = currentPixel.g;
    lowp float currentBlue = currentPixel.b;
    
    lowp float currentY = 0.299*currentRed + 0.587*currentGreen+ 0.114*currentBlue;
    lowp float currentU = (-0.14713)*currentRed + (-0.28886)*currentGreen + (0.436)*currentBlue;
    lowp float currentV = 0.615*currentRed + (-0.51499)*currentGreen + (-0.10001)*currentBlue;
    lowp vec3 currentYUV = vec3(currentY,currentU,currentV);
    
    if ((TexCoordOut.x > 0.5) || (TexCoordOut.y > 0.5)) {
        gl_FragColor = currentPixel; // New
    } else {
        
        for (int i=0; i<16; i++) {
            for (int j=0; j<16; j++) {
                lowp vec2 coord = vec2(i,j);
                lowp vec4 samplePixel = texture2D(Texture, coord);
                lowp float sampleRed = samplePixel.r;
                lowp float sampleGreen = samplePixel.g;
                lowp float sampleBlue = samplePixel.b;
                
                lowp float sampleY = 0.299*sampleRed + 0.587*sampleGreen+ 0.114*sampleBlue;
                lowp float sampleU = (-0.14713)*sampleRed + (-0.28886)*sampleGreen + (0.436)*sampleBlue;
                lowp float sampleV = 0.615*sampleRed + (-0.51499)*sampleGreen + (-0.10001)*sampleBlue;
                lowp vec3 sampleYUV = vec3(sampleY,sampleU,sampleV);
                
                lowp float d = distance(currentYUV, sampleYUV);
                
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
                    accumulatorR = accumulatorR + 1;
                }
            }
        }
        
        gl_FragColor = vec4(float(accumulatorR)/399.0,currentPixel.g,currentPixel.b,1.0); // New
    }
}