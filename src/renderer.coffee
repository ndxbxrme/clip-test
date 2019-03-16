navigator.mediaDevices.getUserMedia
  audio: true
.then (stream) ->
  audio = new AudioContext()
  source = audio.createMediaStreamSource stream
  compressor = audio.createDynamicsCompressor()
  analyser = audio.createAnalyser()
  dest = audio.createMediaStreamDestination()
  source.connect compressor
  compressor.connect analyser
  analyser.connect dest
  analyser.fftSize = 2048
  viz = require('./viz') analyser
  $controls = document.querySelector '.controls'
  $rec = document.querySelector '.rec'
  $clips = document.querySelector '.clips'
  $reduction = document.querySelector '.reduction'
  cutoff =
    toString: ->
      'Cutoff'
  recording = false
  chunks = []
  checkTime = 0
  mediaRecorder = new MediaRecorder dest.stream
  mediaRecorder.ondataavailable = (e) ->
    chunks.push e.data
  mediaRecorder.onstop = (e) ->
    size = 0
    for chunk in chunks
      size += chunk.size
    if size > cutoff.min_size
      $audio = document.createElement 'audio'
      $audio.controls = true
      blob = new Blob chunks,
        type: 'audio/ogg; codec=opus'
      audioURL = URL.createObjectURL blob
      $audio.src = audioURL
      $clips.appendChild $audio
    chunks = []
  connectRange = (component, prop, val, step, min, max) ->
    $control = document.createElement 'div'
    $control.className = 'control'
    input = document.createElement 'input'
    input.type = 'range'
    input.min = component[prop]?.minValue or min or 0
    input.max = component[prop]?.maxValue or max or 0
    input.step = step
    input.value = val
    label = document.createElement 'label'
    labelText = (myval) ->
      component.toString().replace(/\[object |Node\]/g, '') + ', ' + prop + ', ' + myval
    input.oninput = (e) ->
      if component[prop]?.setValueAtTime
        component[prop].setValueAtTime input.value, audio.currentTime
      else
        component[prop] = input.value
      label.innerHTML = labelText input.value
    input.oninput()
    $controls.appendChild $control
    $control.appendChild label
    $control.appendChild input
  connectRange compressor, 'threshold', -75, 1
  connectRange compressor, 'knee', 40, 1
  connectRange compressor, 'ratio', 20, 0.1
  connectRange compressor, 'attack', 0, 0.01
  connectRange compressor, 'release', 0.25, 0.01
  connectRange cutoff, 'time', .5, 0.01, 0, 5
  connectRange cutoff, 'threshold', -10, 0.1, -40, 0
  connectRange cutoff, 'min_size', 20000, 100, 1000, 100000

  process = ->
    requestAnimationFrame process
    viz.draw()
    $reduction.style.width = Math.min(100,(-compressor.reduction * 100 / 60)) + '%'
    if compressor.reduction < +cutoff.threshold
      if not recording
        mediaRecorder.start()
        $rec.className = 'rec recording'
        recording = true
        checkTime = 0
    else
      if not checkTime
        checkTime = audio.currentTime + +cutoff.time
      else
        if audio.currentTime > checkTime
          if recording
            mediaRecorder.stop()
            $rec.className = 'rec'
            recording = false
          checkTime = 0
  process()
module.exports =
  deleteAllClips: ->
    clips = document.querySelectorAll 'audio'
    for clip in clips
      clip.parentNode.removeChild clip