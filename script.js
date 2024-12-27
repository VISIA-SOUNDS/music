const samples = [
    "sample1.wav",
    "sample2.wav",
    "sample3.wav",
    "sample4.wav",
    "sample5.wav",
    "sample6.wav",
    "sample7.wav",
    "sample8.wav",
    "sample9.wav"
  ];
  
  const audioContext = new (window.AudioContext || window.webkitAudioContext)();
  const squares = document.querySelectorAll(".square");
  const audioBuffers = new Array(samples.length);
  let activeNodes = new Array(samples.length).fill(null);
  let sharedStartTime = null;
  
  // Load WAV files into buffers
  async function loadAudio() {
    for (let i = 0; i < samples.length; i++) {
      const response = await fetch(samples[i]);
      const arrayBuffer = await response.arrayBuffer();
      const audioBuffer = await audioContext.decodeAudioData(arrayBuffer);
      audioBuffers[i] = audioBuffer;
    }
  }
  
  // Play a sample in sync
  function playSample(index) {
    if (!audioBuffers[index]) return;
  
    // Calculate the exact playback offset to maintain sync
    const currentTime = audioContext.currentTime;
    const loopDuration = audioBuffers[index].duration;
    const offset = (currentTime - sharedStartTime) % loopDuration;
  
    // Create a new source node for the sample
    const source = audioContext.createBufferSource();
    source.buffer = audioBuffers[index];
    source.loop = true;
  
    source.connect(audioContext.destination);
    source.start(0, offset); // Start from the exact offset
  
    activeNodes[index] = source;
  }
  
  // Stop a sample
  function stopSample(index) {
    if (activeNodes[index]) {
      activeNodes[index].stop();
      activeNodes[index] = null;
    }
  }
  
  // Toggle playback of a sample
  function toggleSample(index) {
    if (squares[index].classList.contains("active")) {
      // Stop the sample if it's already playing
      stopSample(index);
      squares[index].classList.remove("active");
    } else {
      // Start the sample in sync
      squares[index].classList.add("active");
      playSample(index);
    }
  }
  
  // Initialize audio loading
  loadAudio()
    .then(() => {
      sharedStartTime = audioContext.currentTime;
      console.log("Audio loaded and synchronized!");
    })
    .catch(err => console.error("Error loading audio files:", err));
  
  // Add click event listeners
  squares.forEach((square, index) => {
    square.addEventListener("click", () => {
      toggleSample(index);
    });
  });
  