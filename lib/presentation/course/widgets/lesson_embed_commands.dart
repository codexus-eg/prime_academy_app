/// PlayerJS command snippets executed against `window.__player` in the embed
/// wrapper page ([LessonEmbedSupport.wrapperHtml]).
abstract final class LessonEmbedCommands {
  static String play() => _enqueue('p.play();');

  static String pause() => _enqueue('p.pause();');

  static String seek(double seconds) =>
      _enqueue('p.setCurrentTime(${seconds.toStringAsFixed(3)});');

  static String mute() => _enqueue(
        'if(!p.supports||p.supports("method","mute")){p.mute();}'
        'else if(p.supports("method","setVolume")){p.setVolume(0);}',
      );

  static String unmute() => _enqueue(
        'if(!p.supports||p.supports("method","unmute")){p.unmute();}'
        'else if(p.supports("method","setVolume")){p.setVolume(100);}',
      );

  static String setRate(double rate) => _enqueue(
        'if(!p.supports||p.supports("method","setPlaybackRate")){'
        'p.setPlaybackRate($rate);}',
      );

  static String _enqueue(String body) =>
      'try{if(window.__enqueuePlayerCmd){window.__enqueuePlayerCmd(function(p){$body});}'
      'else{var p=window.__player;if(p){$body}}}catch(e){}';
}
