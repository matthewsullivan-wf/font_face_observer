@TestOn('browser')
import 'dart:html';
import 'dart:async';
import 'package:test/test.dart';
import 'package:font_face_observer/font_face_observer.dart';
import 'package:font_face_observer/src/adobe_blank.dart';

class _FontUrls {
  static const String roboto = 'fonts/Roboto.ttf';
  static const String w = 'fonts/W.ttf';
  static const String empty = 'fonts/empty.ttf';
  static const String subset = 'fonts/subset.ttf';
  static const String fontNotFound = 'fonts/font_not_found.ttf';
}

void main() {
  group('FontFaceObserver', () {
    tearDown(() async {
      while (FontFaceObserver.getLoadedGroups().length > 0) {
        for (String group in FontFaceObserver.getLoadedGroups()) {
          await FontFaceObserver.unloadGroup(group);
        }
      }
    });

    void expectKeyNotLoaded(String key) {
      expect(querySelector('style[data-key="${key}"]'), isNull);
      expect(querySelector('span[data-key="${key}"]'), isNull);
      expect(FontFaceObserver.getLoadedFontKeys().contains(key), isFalse);
    }

    void expectGroupNotLoaded(String group) {
      expect(FontFaceObserver.getLoadedGroups().contains(group), isFalse);
    }

    test('should handle quoted family name', () {
      expect(new FontFaceObserver('"my family"').family, equals('my family'));
      expect(new FontFaceObserver("'my family'").family, equals('my family'));
      expect(new FontFaceObserver("my family").family, equals('my family'));
    });

    test('should init correctly with passed in values', () {
      String family = 'my family';
      String style = 'my style';
      String weight = 'my weight';
      String stretch = 'my stretch';
      String testString = 'my testString';
      int timeout = 1337;

      FontFaceObserver ffo = new FontFaceObserver(family,
          style: style,
          weight: weight,
          stretch: stretch,
          testString: testString,
          useSimulatedLoadEvents: true,
          timeout: timeout);
      expect(ffo, isNotNull);
      expect(ffo.family, equals(family));
      expect(ffo.style, equals(style));
      expect(ffo.weight, equals(weight));
      expect(ffo.stretch, equals(stretch));
      expect(ffo.testString, equals(testString));
      expect(ffo.timeout, equals(timeout));
      expect(ffo.useSimulatedLoadEvents, equals(true));
      ffo.testString = '  ';
      expect(ffo.testString, equals('BESbswy'));
    });
    
    test('should timeout and fail for a bogus font when using FontFace API', () async {
      FontLoadResult result = await new FontFaceObserver('bogus', timeout: 500).load(_FontUrls.fontNotFound);
      expect(result.isLoaded, isFalse);
      expect(result.didTimeout, isTrue);
    });

    test('should detect a bogus font with simulated events', () async {
      FontLoadResult result = await new FontFaceObserver('bogus2', timeout: 100, useSimulatedLoadEvents: true).load(_FontUrls.fontNotFound);
      expect(result.isLoaded, isTrue);
      expect(result.didTimeout, isFalse);
    });

    test('should load a real font', () async {
      FontLoadResult result = await new FontFaceObserver('test1').load(_FontUrls.roboto);
      expect(result.isLoaded, isTrue);
    });

    test('should load a real font using simulated events', () async {
      FontFaceObserver ffo = new FontFaceObserver('test2', useSimulatedLoadEvents: true);
      FontLoadResult result = await ffo.load(_FontUrls.roboto);
      expect(result.isLoaded, isTrue);
      result = await ffo.check();
      expect(result.isLoaded, isTrue);
    });

    test('should track the font keys and groups correctly', () async {
      await new FontFaceObserver('font_keys1').load(_FontUrls.roboto);
      await new FontFaceObserver('font_keys2').load(_FontUrls.roboto);
      await new FontFaceObserver('font_keys3', group: 'group_1').load(_FontUrls.roboto);
      await new FontFaceObserver('font_keys4', group: 'group_2').load(_FontUrls.roboto);

      // AdobeBlank is always loaded, so expect that too
      Iterable<String> keys = FontFaceObserver.getLoadedFontKeys();
      expect(keys.length, equals(5));
      expect(keys.contains('font_keys1_normal_normal_normal'), isTrue);
      expect(keys.contains('font_keys2_normal_normal_normal'), isTrue);
      expect(keys.contains('font_keys3_normal_normal_normal'), isTrue);
      expect(keys.contains('font_keys4_normal_normal_normal'), isTrue);
      expect(keys.contains(adobeBlankKey), isTrue);

      // expect the default group too
      Iterable<String> groups = FontFaceObserver.getLoadedGroups();
      expect(groups.length, equals(4));
      expect(groups.contains(FontFaceObserver.defaultGroup), isTrue);
      expect(groups.contains('group_1'), isTrue);
      expect(groups.contains('group_2'), isTrue);
      expect(groups.contains(adobeBlankFamily), isTrue);
    });

    test('should not leave temp DOM nodes after detecting', () async {
      FontFaceObserver ffo = new FontFaceObserver('no_dom_leaks', useSimulatedLoadEvents: true);
      FontLoadResult result = await ffo.load(_FontUrls.roboto);
      expect(result.isLoaded, isTrue);
      ElementList<Element> elements = querySelectorAll('._ffo_temp');
      if (elements.length > 0) {
        elements.forEach( (Element el) => print('${el.tagName}.${el.className}'));
      }
      expect(elements.length, isZero);
    });

    test('should unload a font by key', () async {
      FontFaceObserver ffo = new FontFaceObserver('unload_by_key');
      String key = ffo.key;
      FontLoadResult result = await ffo.load(_FontUrls.roboto);
      expect(result.isLoaded, isTrue);
      await FontFaceObserver.unload(key, ffo.group);
      Element styleElement = querySelector('style[data-key="${key}"]');
      expect(styleElement,isNull);
    });

    test('should use the default group if no group specified', () async {
      FontFaceObserver ffo = new FontFaceObserver('default_group1');
      expect(ffo.group, equals(FontFaceObserver.defaultGroup));
    });

    test('should unload a font by group', () async {
      String group = 'somegroup';
      await new FontFaceObserver('unload_by_group1', group: group).load(_FontUrls.roboto);
      await new FontFaceObserver('unload_by_group2', group: group).load(_FontUrls.roboto);
      await FontFaceObserver.unloadGroup(group);
      expect(querySelectorAll('style[data-group="${group}"]').length, isZero);
    });


    test('should keep data-uses attribute up to date', () async {
      String differentGroup = 'diff';
      FontFaceObserver ffo = new FontFaceObserver('uses_test');
      String key = ffo.key;
      FontLoadResult result = await ffo.load(_FontUrls.roboto);
      expect(result.isLoaded, isTrue);
      Element styleElement = querySelector('style[data-key="${key}"]');
      expect(styleElement.dataset['uses'],'1');

      // load it again with the same group, uses should be 2
      result = await ffo.load(_FontUrls.roboto);
      expect(result.isLoaded, isTrue);
      expect(styleElement.dataset['uses'],'2');

      // load it again with a different group, uses should be 3
      FontFaceObserver ffo2 = new FontFaceObserver('uses_test', group: differentGroup);
      result = await ffo2.load(_FontUrls.roboto);
      expect(result.isLoaded, isTrue);
      expect(styleElement.dataset['uses'],'3');

      // unload it once with the default group
      expect(await FontFaceObserver.unload(key, ffo.group), isTrue);
      expect(styleElement.dataset['uses'],'2');

      // unload the 2nd load
      expect(await FontFaceObserver.unload(ffo2.key, ffo2.group), isTrue);
      expect(styleElement.dataset['uses'],'1');

      // unload it completely
      expect(await FontFaceObserver.unload(key, ffo.group), isTrue);
      // unload it again, should not go negative
      expect(await FontFaceObserver.unload(key, ffo.group), isFalse);
      expect(querySelector('style[data-key="${key}"]'), isNull);
      expect(querySelector('span[data-key="${key}"]'), isNull);
      expect(styleElement.dataset['uses'],'0');
    });

    test('should timeout on an empty font, not throw an exception', () async {
      FontLoadResult result = await new FontFaceObserver('empty1', timeout: 100).load(_FontUrls.empty);
      expect(result.isLoaded, isFalse);
      expect(result.didTimeout, isTrue);
    });

    test('should detect an empty font, not throw an exception with simulated events', () async {
      FontLoadResult result = await new FontFaceObserver('empty2', timeout: 100, useSimulatedLoadEvents: true).load(_FontUrls.empty);
      expect(result.isLoaded, isTrue);
      expect(result.didTimeout, isFalse);
    });

    test('should load user-region-only font', () async {
      FontLoadResult result = await new FontFaceObserver('w', timeout: 100, testString: '\uE0FF').load(_FontUrls.w); // 57599
      expect(result.isLoaded, isTrue);
      expect(result.didTimeout, isFalse);
    });

    test('should find the font if it is already loaded', () async {
      await new FontFaceObserver('test3').load(_FontUrls.roboto);
      FontLoadResult result = await new FontFaceObserver('test3').check();
      expect(result.isLoaded, isTrue);
    });

    test('should cleanup when not successful', () async {
      FontFaceObserver ffo1 = new FontFaceObserver('cleanup1', timeout: 100, group: 'group1');
      FontFaceObserver ffo2 = new FontFaceObserver('cleanup2', timeout: 100, group: 'group2');

      FontLoadResult result1 = await ffo1.load(_FontUrls.empty);
      FontLoadResult result2 = await ffo2.load(_FontUrls.fontNotFound);
    
      expect(result1.isLoaded, isFalse);
      expect(result2.isLoaded, isFalse);
      expectKeyNotLoaded(ffo1.key);
      expectKeyNotLoaded(ffo2.key);
      expectGroupNotLoaded(ffo1.group);
      expectGroupNotLoaded(ffo2.group);
    });

    test('should handle async interleaved load and unload calls', () async {
      FontFaceObserver ffo1 = new FontFaceObserver('complex1', group: 'group1');
      
      // fire this off async
      Future<FontLoadResult> f1 = ffo1.load(_FontUrls.roboto);
      await FontFaceObserver.unloadGroup(ffo1.group);
      await f1;
      expectKeyNotLoaded(ffo1.key);
      expectGroupNotLoaded(ffo1.group);
    });

    test('should handle spaces and numbers in font family', () async {
      FontLoadResult result = await new FontFaceObserver('Garamond 7').load(_FontUrls.roboto);
      expect(result.isLoaded, isTrue);
    });

    test('should find a font with a custom unicode range within ASCII', () async {
      FontLoadResult result = await new FontFaceObserver('unicode1', testString: '\u0021').load(_FontUrls.subset);
      expect(result.isLoaded, isTrue);
    });

    test('should find a font with a custom unicode range outside ASCII (but within BMP)', () async {
      FontLoadResult result = await new FontFaceObserver('unicode2', testString: '\u4e2d\u56fd').load(_FontUrls.subset);
      expect(result.isLoaded, isTrue);
    });

    test('should find a font with a custom unicode range outside the BMP', () async {
      FontLoadResult result = await new FontFaceObserver('unicode3', testString: '\udbff\udfff').load(_FontUrls.subset);
      expect(result.isLoaded, isTrue);
    });

    test('should find a font with a custom unicode range within ASCII with simulated events', () async {
      FontLoadResult result = await new FontFaceObserver('unicode1', testString: '\u0021', useSimulatedLoadEvents: true).load(_FontUrls.subset);
      expect(result.isLoaded, isTrue);
    });

    test('should find a font with a custom unicode range outside ASCII (but within BMP) with simulated events', () async {
      FontLoadResult result = await new FontFaceObserver('unicode2', testString: '\u4e2d\u56fd', useSimulatedLoadEvents: true).load(_FontUrls.subset);
      expect(result.isLoaded, isTrue);
    });

    test('should find a font with a custom unicode range outside the BMP with simulated events', () async {
      FontLoadResult result = await new FontFaceObserver('unicode3', testString: '\udbff\udfff', useSimulatedLoadEvents: true).load(_FontUrls.subset);
      expect(result.isLoaded, isTrue);
    });
  });
}
