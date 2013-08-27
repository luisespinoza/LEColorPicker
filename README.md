LEColorPicker
=============

A Cocoa-Touch system for getting a color scheme in function of an image, like iTunes 11 does. It is designed as a general purpose class set, in wich  LEColorPicker is the interface for your client code.

![LEColorPicker_Vortex](https://raw.github.com/luisespinoza/LEColorPicker/master/Screenshot_Vortex.png)
![LEColorPicker_Mona](https://raw.github.com/luisespinoza/LEColorPicker/master/Screenshot_Mona.png)

**Release note:** Current release (1.0) run faster in devices than simulator.


## Installation

* Add the OpenGLES framework to your project.
* Drag the 'LEColorPickerDemo/LEColorPicker' folder into your project, and you are done.

## Usage
First, you have to create an instance of a `LEColorPicker` object. Then, `LEColorPicker` class provides an instance method that receives an UIImage as input and returns a `LEColorScheme` object. LEColorScheme will provide the three computed colors as properties.

    #import "LEColorPicker.h"
    ...
    LEColorPicker *colorPicker = [[LEColorPicker alloc] init];
    LEColorScheme *colorScheme = [colorPicker colorSchemeFromImage:image];
    aView.backgroundColor = [colorScheme backgroundColor];
    titleTextField.textColor = [colorScheme primaryTextColor];
    bodyTextField.textColor = [colorScheme secondaryTextColor];
	...
	
## About the sample images
All images are public domain. If you want to add your own testing images, drag the image to the Resources folder of the project, in Xcode. Don't use names with "Default" or will be filtered. Only PNG images are supported (for now) in the sample project.

## License

This software is licensed under the MIT license.

	Copyright (c) 2012 Luis Espinoza

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
	files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
	modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the 
	Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the 
	Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE 
	WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR 
	COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, 
	ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.	

## Thanks to
Andrey Tarantsov for [ATPagingView](https://github.com/andreyvit/SoloComponents-iOS).

User Olie from StackOverflow, [for his function to get a RGBA pixel array from an UIImage](http://goo.gl/PEUhq).

User Seth Thompson from StackOverflow for his [Mathematica code for pick the colors like iTunes 11](http://goo.gl/sJ2DH).

[Ray Wenderlich tutorials](http://www.raywenderlich.com).

## Contact
Suggestions will be well received.

Mail [luis.espinoza.severino@gmail.com](mailto:luis.espinoza.severino@gmail.com)

Twitter [@luis_espinoza](https://twitter.com/luis_espinoza)

## MacBuildServer
You can try the demo in your device via MacBuildServer.

<!-- MacBuildServer Install Button -->
<div class="macbuildserver-block">
    <a class="macbuildserver-button" href="http://macbuildserver.com/project/github/build/?xcode_project=LEColorPickerDemo.xcodeproj&amp;target=LEColorPickerDemo&amp;repo_url=git%3A%2F%2Fgithub.com%2Fluisespinoza%2FLEColorPicker.git&amp;build_conf=Release" target="_blank"><img src="http://com.macbuildserver.github.s3-website-us-east-1.amazonaws.com/button_up.png"/></a><br/><sup><a href="http://macbuildserver.com/github/opensource/" target="_blank">by MacBuildServer</a></sup>
</div>
<!-- MacBuildServer Install Button -->
