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
    lowp float currentRed = currentPixel.r;
    lowp float currentGreen = currentPixel.g;
    lowp float currentBlue = currentPixel.b;
    
    lowp float currentY = 0.299*currentRed + 0.587*currentGreen+ 0.114*currentBlue;
    lowp float currentU = (-0.14713)*currentRed + (-0.28886)*currentGreen + (0.436)*currentBlue;
    lowp float currentV = 0.615*currentRed + (-0.51499)*currentGreen + (-0.10001)*currentBlue;
    lowp vec3 currentYUV = vec3(currentY,currentU,currentV);
    
    if ((TexCoordOut.x > 0.5) || (TexCoordOut.y > 0.5)) {
        gl_FragColor = vec4(0.0,0.0,0.0,1.0); // New
    } else {
        
        for (int i=0; i<32; i++) {
            for (int j=0; j<32; j++) {
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
                    accumulator = accumulator + 1.0;
                }
                
            }
        }
        
        
        
        gl_FragColor = vec4(accumulator,0.0,0.0,1.0); // New
    }
}