//
//  DominantColor.vsh
//  LEColorPicker
//
//  Created by Luis Enrique Espinoza Severino on 07-03-13.
//  Copyright (c) 2013 Luis Espinoza. All rights reserved.
//

attribute vec4 position;
attribute vec4 sourceColor;

varying vec4 destinationColor;

attribute vec2 texCoordIn;
varying vec2 texCoordOut;

void main()
{
    destinationColor = sourceColor;
    gl_Position = position;
    texCoordOut = texCoordIn;
}
