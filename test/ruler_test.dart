/*
Copyright 2017 Workiva Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

This software or document includes material copied from or derived 
from fontfaceobserver (https://github.com/bramstein/fontfaceobserver), 
Copyright (c) 2014 - Bram Stein, which is licensed under the following terms:

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions 
are met:
 
 1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer. 
 2. Redistributions in binary form must reproduce the above copyright 
    notice, this list of conditions and the following disclaimer in the 
    documentation and/or other materials provided with the distribution. 

THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED 
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO 
EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

This software or document includes material copied from or derived from 
CSS Font Loading Module Level 3 (https://drafts.csswg.org/css-font-loading/)
Copyright © 2017 W3C® (MIT, ERCIM, Keio, Beihang) which is licensed 
under the following terms:

By obtaining and/or copying this work, you (the licensee) agree that you 
have read, understood, and will comply with the following terms and conditions.
Permission to copy, modify, and distribute this work, with or without 
modification, for any purpose and without fee or royalty is hereby granted, 
provided that you include the following on ALL copies of the work or portions 
thereof, including modifications:
The full text of this NOTICE in a location viewable to users of the 
redistributed or derivative work. Any pre-existing intellectual property 
disclaimers, notices, or terms and conditions. If none exist, the W3C 
Software and Document Short Notice should be included.
Notice of any changes or modifications, through a copyright statement 
on the new code or document such as "This software or document 
includes material copied from or derived from 
[title and URI of the W3C document]. 
Copyright © [YEAR] W3C® (MIT, ERCIM, Keio, Beihang)."

https://www.w3.org/Consortium/Legal/2015/copyright-software-and-document
*/
@TestOn('browser')
import 'dart:async';
import 'dart:html';
import 'package:test/test.dart';
import 'package:font_face_observer/src/ruler.dart';

const int _startWidth = 100;

void main() {
  Ruler ruler;

  setUp(() {
    ruler = Ruler('hello')
      ..setFont('')
      ..setWidth(_startWidth);
    document.body.append(ruler.element);
  });

  tearDown(() {
    ruler.element.remove();
    ruler = null;
  });

  Future<Null> testResize(num width1) async {
    final Completer<Null> c = Completer<Null>();
    ruler
      ..onResize((num width) {
        expect(width, equals(width1));
        c.complete();
      })
      ..setWidth(width1);
    return c.future;
  }

  Future<Null> testTwoResizes(num width1, num width2) async {
    final Completer<Null> c = Completer<Null>();
    bool first = true;
    ruler
      ..onResize((num width) {
        if (first) {
          expect(width, equals(width1));
          first = false;
          ruler.setWidth(width2);
        } else {
          expect(width, equals(width2));
          c.complete();
        }
      })
      ..setWidth(width1);
    return c.future;
  }

  group('Ruler', () {
    test('constructor should init correctly', () {
      expect(ruler, isNotNull);
      expect(ruler.element, isNotNull);
      expect(ruler.getWidth(), equals(_startWidth));
    });

    test('should detect expansion', () async => testResize(_startWidth + 100));

    test('should detect collapse', () async => testResize(_startWidth - 50));

    test('should not detect a set to the same width', () async {
      bool failed = false;
      ruler
        ..onResize((num width) {
          failed = true;
        })
        ..setWidth(_startWidth);
      final Completer<Null> c = Completer<Null>();
      Timer(const Duration(milliseconds: 20), () {
        expect(failed, isFalse);
        expect(ruler.getWidth(), equals(_startWidth));
        c.complete();
      });
      return c.future;
    });

    test('should detect multiple expansions',
        () async => testTwoResizes(_startWidth + 100, _startWidth + 200));

    test('should detect multiple collapses',
        () async => testTwoResizes(_startWidth - 30, _startWidth - 50));

    test('should detect an expansion and a collapse',
        () async => testTwoResizes(_startWidth + 100, _startWidth));

    test('should detect a collapse and an expansion',
        () async => testTwoResizes(_startWidth - 30, _startWidth));

    test('should detect single pixel collapses',
        () async => testTwoResizes(_startWidth - 1, _startWidth - 2));

    test('should detect single pixel expansions',
        () async => testTwoResizes(_startWidth + 1, _startWidth + 2));
  });
}
