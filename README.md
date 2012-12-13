LEColorPicker
=============

A Cocoa-Touch system for getting a color scheme in function of an image, like iTunes 11 does. It is designed as a general purpose class set, in wich  LEColorPicker is the interface for your client code.

![LEColorPicker_Vortex](https://raw.github.com/luisespinoza/LEColorPicker/master/Screenshot_Vortex.png)
![LEColorPicker_Mona](https://raw.github.com/luisespinoza/LEColorPicker/master/Screenshot_Mona.png)

At is this moment, still needs a lot of work, and the colors sets are not exactly Itunes sets. 

Suggestions will be well received, and check this periodically to know the updates.

## Installation
THIS PROJECT USE ARC!!!

* Drag the 'LEColorPickerDemo/LEColorPicker' folder into your project, and you are done.

## Usage
LEColorPicker class provides a class method that receives an UIImage as input and returns a NSDictionary with the three computed colors. The computation take some time, that is why you have to use it inside a dispatch_async block. Notice that you have to dispatch to the main queue the block for using the computed colors.



	#import "LEColorPicker.h"
	...
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *colorsPickedDictionary = [LEColorPicker dictionaryWithColorsPickedFromImage:image];
        dispatch_async(dispatch_get_main_queue(), ^{
            _outputView.backgroundColor = [colorsPickedDictionary objectForKey:@"BackgroundColor"];
            _titleTextField.textColor = [colorsPickedDictionary objectForKey:@"PrimaryTextColor"];
            _bodyTextField.textColor = [colorsPickedDictionary objectForKey:@"SecondaryTextColor"];
        });
    });
	...
	


## License

This software is licensed under the MIT license.

	Copyright (c) 2012 Luis Espinoza

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Thanks to
Andrey Tarantsov for [ATPagingView](https://github.com/andreyvit/SoloComponents-iOS).

User Olie from StackOverflow, [for his function to get a RGBA pixel array from a UIImage](http://goo.gl/PEUhq).

User Seth Thompson from StackOverflow for his [Mathematica code for pick the colors like iTunes 11](http://goo.gl/sJ2DH).