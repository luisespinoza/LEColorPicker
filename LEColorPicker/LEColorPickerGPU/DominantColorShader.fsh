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
    //gl_FragColor = DestinationColor * texture2D(Texture, TexCoordOut); // New
    gl_FragColor = DestinationColor;
   // gl_FragColor = texture2D(Texture, TexCoordOut);
}
