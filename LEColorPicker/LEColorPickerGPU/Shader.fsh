//
//  Shader.fsh
//  LearningOpenGLES
//
//  Created by Luis Enrique Espinoza Severino on 07-03-13.
//  Copyright (c) 2013 Luis Espinoza. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
