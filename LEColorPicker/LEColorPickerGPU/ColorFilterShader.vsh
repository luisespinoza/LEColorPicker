//
//  ColorFilterShader.vsh
//  LEColorPicker
//
//  Created by Luis Enrique Espinoza Severino on 07-03-13.
//  Copyright (c) 2013 Luis Espinoza. All rights reserved.
//

attribute vec4 Position;
attribute vec4 SourceColor;

varying vec4 DestinationColor;

attribute vec2 TexCoordIn; // New
varying vec2 TexCoordOut; // New

void main(void) {
    DestinationColor = SourceColor;
    gl_Position = Position;
    TexCoordOut = TexCoordIn; // New
}
