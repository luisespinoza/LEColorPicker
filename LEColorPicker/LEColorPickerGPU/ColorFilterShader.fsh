//
//  ColorFilterShader.fsh
//  LEColorPicker
//
//  Created by Luis Enrique Espinoza Severino on 07-03-13.
//  Copyright (c) 2013 Luis Espinoza. All rights reserved.
//

varying lowp vec4 destinationColor;
varying lowp vec2 texCoordOut;
uniform sampler2D texture;

void main()
{
    gl_FragColor = destinationColor * texture2D(texture, texCoordOut);
}
