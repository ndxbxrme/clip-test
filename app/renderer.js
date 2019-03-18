(function() {
  navigator.mediaDevices.getUserMedia({
    audio: true
  }).then(function(stream) {
    var $clips, $controls, $rec, $reduction, analyser, audio, checkTime, chunks, compressor, connectRange, cutoff, dest, mediaRecorder, process, recording, source, viz;
    audio = new AudioContext();
    source = audio.createMediaStreamSource(stream);
    compressor = audio.createDynamicsCompressor();
    analyser = audio.createAnalyser();
    dest = audio.createMediaStreamDestination();
    source.connect(compressor);
    compressor.connect(analyser);
    analyser.connect(dest);
    analyser.fftSize = 2048;
    viz = require('./viz')(analyser);
    $controls = document.querySelector('.controls');
    $rec = document.querySelector('.rec');
    $clips = document.querySelector('.clips');
    $reduction = document.querySelector('.reduction');
    cutoff = {
      toString: function() {
        return 'Cutoff';
      }
    };
    recording = false;
    chunks = [];
    checkTime = 0;
    mediaRecorder = new MediaRecorder(dest.stream);
    mediaRecorder.ondataavailable = function(e) {
      return chunks.push(e.data);
    };
    mediaRecorder.onstop = function(e) {
      var $audio, audioURL, blob, chunk, i, len, size;
      size = 0;
      for (i = 0, len = chunks.length; i < len; i++) {
        chunk = chunks[i];
        size += chunk.size;
      }
      if (size > cutoff.min_size) {
        $audio = document.createElement('audio');
        $audio.controls = true;
        blob = new Blob(chunks, {
          type: 'audio/ogg; codec=opus'
        });
        audioURL = URL.createObjectURL(blob);
        $audio.src = audioURL;
        $clips.appendChild($audio);
      }
      return chunks = [];
    };
    connectRange = function(component, prop, val, step, min, max) {
      var $control, input, label, labelText, ref, ref1;
      $control = document.createElement('div');
      $control.className = 'control';
      input = document.createElement('input');
      input.type = 'range';
      input.min = ((ref = component[prop]) != null ? ref.minValue : void 0) || min || 0;
      input.max = ((ref1 = component[prop]) != null ? ref1.maxValue : void 0) || max || 0;
      input.step = step;
      input.value = val;
      label = document.createElement('label');
      labelText = function(myval) {
        return component.toString().replace(/\[object |Node\]/g, '') + ', ' + prop + ', ' + myval;
      };
      input.oninput = function(e) {
        var ref2;
        if ((ref2 = component[prop]) != null ? ref2.setValueAtTime : void 0) {
          component[prop].setValueAtTime(input.value, audio.currentTime);
        } else {
          component[prop] = input.value;
        }
        return label.innerHTML = labelText(input.value);
      };
      input.oninput();
      $controls.appendChild($control);
      $control.appendChild(label);
      return $control.appendChild(input);
    };
    connectRange(compressor, 'threshold', -75, 1);
    connectRange(compressor, 'knee', 40, 1);
    connectRange(compressor, 'ratio', 20, 0.1);
    connectRange(compressor, 'attack', 0, 0.01);
    connectRange(compressor, 'release', 0.25, 0.01);
    connectRange(cutoff, 'time', .5, 0.01, 0, 5);
    connectRange(cutoff, 'threshold', -10, 0.1, -40, 0);
    connectRange(cutoff, 'min_size', 20000, 100, 1000, 100000);
    process = function() {
      requestAnimationFrame(process);
      viz.draw();
      $reduction.style.width = Math.min(100, -compressor.reduction * 100 / 60) + '%';
      if (compressor.reduction < +cutoff.threshold) {
        if (!recording) {
          mediaRecorder.start();
          $rec.className = 'rec recording';
          recording = true;
          return checkTime = 0;
        }
      } else {
        if (!checkTime) {
          return checkTime = audio.currentTime + +cutoff.time;
        } else {
          if (audio.currentTime > checkTime) {
            if (recording) {
              mediaRecorder.stop();
              $rec.className = 'rec';
              recording = false;
            }
            return checkTime = 0;
          }
        }
      }
    };
    return process();
  });

  module.exports = {
    deleteAllClips: function() {
      var clip, clips, i, len, results;
      clips = document.querySelectorAll('audio');
      results = [];
      for (i = 0, len = clips.length; i < len; i++) {
        clip = clips[i];
        results.push(clip.parentNode.removeChild(clip));
      }
      return results;
    }
  };

}).call(this);

//# sourceMappingURL=renderer.js.map
