#
#  Simple DirectMedia Layer
#  Copyright (C) 1997-2014 Sam Lantinga <slouken@libsdl.org>
#
#  This software is provided 'as-is', without any express or implied
#  warranty.  In no event will the authors be held liable for any damages
#  arising from the use of this software.
#
#  Permission is granted to anyone to use this software for any purpose,
#  including commercial applications, and to alter it and redistribute it
#  freely, subject to the following restrictions:
#
#  1. The origin of this software must not be misrepresented; you must not
#     claim that you wrote the original software. If you use this software
#     in a product, an acknowledgment in the product documentation would be
#     appreciated but is not required.
#  2. Altered source versions must be plainly marked as such, and must not be
#     misrepresented as being the original software.
#  3. This notice may not be removed or altered from any source distribution.
#

##  audio.nim
##  =========
##
##  Access to the raw audio mixing buffer for the SDL library.

type
  AudioFormat* = uint16 ##  \
    ##  Audio format flags.
    ##
    ##  These are what the 16 bits in ``AudioFormat`` currently mean...
    ##  (Unspecified bits are always zero).
    ##
    ##  ::
    ##    ++-----------------------sample is signed if set
    ##    ||
    ##    ||       ++-----------sample is bigendian if set
    ##    ||       ||
    ##    ||       ||          ++---sample is float if set
    ##    ||       ||          ||
    ##    ||       ||          || +---sample bit size---+
    ##    ||       ||          || |                     |
    ##    15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00
    ##
    ##  There are templates in SDL 2.0 and later to query these bits.

# Audio flags
const
  AUDIO_MASK_BITSIZE* = 0x000000FF
  AUDIO_MASK_DATATYPE* = (1 shl 8)
  AUDIO_MASK_ENDIAN* = (1 shl 12)
  AUDIO_MASK_SIGNED* = (1 shl 15)

template audioBitSize*(x: expr): expr =
  (x and AUDIO_MASK_BITSIZE)

template audioIsFloat*(x: expr): expr =
  (x and AUDIO_MASK_DATATYPE)

template audioIsBigEndian*(x: expr): expr =
  (x and AUDIO_MASK_ENDIAN)

template audioIsSigned*(x: expr): expr =
  (x and AUDIO_MASK_SIGNED)

template audioIsInt*(x: expr): expr =
  (not audioIsFloat(x))

template audioIsLittleEndian*(x: expr): expr =
  (not audioIsBigEndian(x))

template audioIsUnsigned*(x: expr): expr =
  (not audioIsSigned(x))

# Audio format flags
#
# Defaults to LSB byte order.
const
  AUDIO_U8*     = 0x00000008  ##  Unsigned 8-bit samples
  AUDIO_S8*     = 0x00008008  ##  Signed 8-bit samples
  AUDIO_U16LSB* = 0x00000010  ##  Unsigned 16-bit samples
  AUDIO_S16LSB* = 0x00008010  ##  Signed 16-bit samples
  AUDIO_U16MSB* = 0x00001010  ##  As above, but big-endian byte order
  AUDIO_S16MSB* = 0x00009010  ##  As above, but big-endian byte order
  AUDIO_U16* = AUDIO_U16LSB
  AUDIO_S16* = AUDIO_S16LSB

# int32 support
const
  AUDIO_S32LSB* = 0x00008020  ##  32-bit integer samples
  AUDIO_S32MSB* = 0x00009020  ##  As above, but big-endian byte order
  AUDIO_S32* = AUDIO_S32LSB

# float32 support
const
  AUDIO_F32LSB* = 0x00008120  ##  32-bit floating point samples
  AUDIO_F32MSB* = 0x00009120  ##  As above, but big-endian byte order
  AUDIO_F32* = AUDIO_F32LSB

# Native audio byte ordering
when(cpuEndian == littleEndian):
  const
    AUDIO_U16SYS* = AUDIO_U16LSB
    AUDIO_S16SYS* = AUDIO_S16LSB
    AUDIO_S32SYS* = AUDIO_S32LSB
    AUDIO_F32SYS* = AUDIO_F32LSB
else:
  const
    AUDIO_U16SYS* = AUDIO_U16MSB
    AUDIO_S16SYS* = AUDIO_S16MSB
    AUDIO_S32SYS* = AUDIO_S32MSB
    AUDIO_F32SYS* = AUDIO_F32MSB

# Allow change flags
#
# Which audio format changes are allowed when opening a device.
const
  AUDIO_ALLOW_FREQUENCY_CHANGE* = 0x00000001
  AUDIO_ALLOW_FORMAT_CHANGE*    = 0x00000002
  AUDIO_ALLOW_CHANNELS_CHANGE*  = 0x00000004
  AUDIO_ALLOW_ANY_CHANGE*       = (AUDIO_ALLOW_FREQUENCY_CHANGE or
                                   AUDIO_ALLOW_FORMAT_CHANGE or
                                   AUDIO_ALLOW_CHANNELS_CHANGE)

# Audio flags

type
  AudioCallback* = proc (userdata: pointer; stream: ptr uint8; len: cint) {.
      cdecl.} ##  \
    ##  This function is called when the audio device needs more data.
    ##
    ##  ``userdata`` An application-specific parameter
    ##  saved in ``AudioSpec`` object.
    ##
    ##  ``stream`` A pointer to the audio data buffer.
    ##
    ##  ``len`` The length of that buffer in bytes.
    ##
    ##  Once the callback returns, the buffer will no longer be valid.
    ##  Stereo samples are stored in a LRLRLR ordering.


type
  AudioSpec* = object ##  \
    ##  The calculated values in this object are calculated by ``OpenAudio()``.
    freq*: cint             ##  DSP frequency -- samples per second
    format*: AudioFormat    ##  Audio data format
    channels*: uint8        ##  Number of channels: `1` mono, `2` stereo
    silence*: uint8         ##  Audio buffer silence value (calculated)
    samples*: uint16        ##  Audio buffer size in samples (power of 2)
    padding*: uint16        ##  Necessary for some compile environments
    size*: uint32           ##  Audio buffer size in bytes (calculated)
    callback*: AudioCallback
    userdata*: pointer

type
  AudioFilter* = proc (cvt: ptr AudioCVT; format: AudioFormat) {.cdecl.}

  AudioCVT* = object {.packed.} ##  \
    ##  A structure to hold a set of audio conversion filters and buffers.
    ##
    ##  This structure is 84 bytes on 32-bit architectures, make sure GCC
    ##  doesn't pad it out to 88 bytes to guarantee ABI compatibility between
    ##  compilers. The next time we rev the ABI, make sure to size the ints
    ##  and add padding.
    needed*: cint             ##  Set to `1` if conversion possible
    src_format*: AudioFormat  ##  Source audio format
    dst_format*: AudioFormat  ##  Target audio format
    rate_incr*: cdouble       ##  Rate conversion increment
    buf*: ptr uint8           ##  Buffer to hold entire audio data
    len*: cint                ##  Length of original audio buffer
    len_cvt*: cint            ##  Length of converted audio buffer
    len_mult*: cint           ##  buffer must be `len*len_mult` big
    len_ratio*: cdouble       ##  Given len, final size is `len*len_ratio`
    filters*: array[10, AudioFilter]  ##  Filter list
    filter_index*: cint       ##  Current audio conversion function 

# Function prototypes

proc getNumAudioDrivers*(): cint {.
    cdecl, importc: "SDL_GetNumAudioDrivers", dynlib: SDL2_LIB.}
  ##  Driver discovery functions. 
  ##
  ##  These functions return the list of built in audio drivers, in the
  ##  order that they are normally initialized by default.

proc getAudioDriver*(index: cint): cstring {.
    cdecl, importc: "SDL_GetAudioDriver", dynlib: SDL2_LIB.}
  ##  Driver discovery functions.
  ##
  ##  These functions return the list of built in audio drivers, in the
  ##  order that they are normally initialized by default.

proc audioInit*(driver_name: cstring): cint {.
    cdecl, importc: "SDL_AudioInit", dynlib: SDL2_LIB.}
  ##  Initialization.
  ##
  ##  ``Internal:`` These functions are used internally, and should not be used
  ##  unless you have a specific need to specify the audio driver you want to
  ##  use.  You should normally use ``init()`` or ``initSubSystem()``.

proc audioQuit*() {.
    cdecl, importc: "SDL_AudioQuit", dynlib: SDL2_LIB.}
  ##  Cleanup.
  ##
  ##  ``Internal``: These functions are used internally, and should not be used
  ##  unless you have a specific need to specify the audio driver you want to
  ##  use.  You should normally use ``init()`` or ``initSubSystem()``.

proc getCurrentAudioDriver*(): cstring {.
    cdecl, importc: "SDL_GetCurrentAudioDriver", dynlib: SDL2_LIB.}
  ##  This function returns the name of the current audio driver, or `nil`
  ##  if no driver has been initialized.

proc openAudio*(desired: ptr AudioSpec; obtained: ptr AudioSpec): cint {.
    cdecl, importc: "SDL_OpenAudio", dynlib: SDL2_LIB.}
  ##  This function opens the audio device with the desired parameters, and
  ##  returns `0` if successful, placing the actual hardware parameters in the
  ##  object pointed to by ``obtained``.  If ``obtained`` is `nil`, the audio
  ##  data passed to the callback function will be guaranteed to be in the
  ##  requested format, and will be automatically converted to the hardware
  ##  audio format if necessary.  This function returns `-1` if it failed
  ##  to open the audio device, or couldn't set up the audio thread.
  ##
  ##  When filling in the ``desired`` audio spec object,
  ##  * ``desired.freq`` should be the desired audio frequency
  ##    in samples-per- second.
  ##  * ``desired.format`` should be the desired audio format.
  ##  * ``desired.samples`` is the desired size of the audio buffer,
  ##    in samples.  This number should be a power of two, and may be adjusted
  ##    by the audio driver to a value more suitable for the hardware.
  ##    Good values seem to range between `512` and `8096` inclusive, depending
  ##    on the  application and CPU speed.  Smaller values yield faster
  ##    response time, but can lead to underflow if the application is doing
  ##    heavy processing and cannot fill the audio buffer in time.  A stereo
  ##    sample consists of both right and left channels in LR ordering.
  ##
  ##    Note that the number of samples is directly related to time by the
  ##    following formula:
  ##
  ##    `ms = (samples*1000)/freq`
  ##
  ##  * ``desired.size`` is the size in bytes of the audio buffer, and is
  ##    calculated by ``openAudio()``.
  ##  * ``desired.silence`` is the value used to set the buffer to silence,
  ##    and is calculated by ``openAudio()``.
  ##  * ``desired.callback`` should be set to a function that will be called
  ##    when the audio device is ready for more data.  It is passed a pointer
  ##    to the audio buffer, and the length in bytes of the audio buffer.
  ##    This function usually runs in a separate thread, and so you should
  ##    protect data structures that it accesses by calling ``lockAudio()``
  ##    and ``unlockAudio()`` in your code.
  ##  * ``desired.userdata`` is passed as the first parameter to your callback
  ##    function.
  ##
  ##  The audio device starts out playing silence when it's opened, and should
  ##  be enabled for playing by calling ``pauseAudio(0)`` when you are ready
  ##  for your audio callback function to be called.  Since the audio driver
  ##  may modify the requested size of the audio buffer, you should allocate
  ##  any local mixing buffers after you open the audio device.

type
  AudioDeviceID* = uint32 ##  \
  ##  SDL Audio Device IDs.
  ##
  ##  A successful call to ``openAudio()`` is always device id `1`, and legacy
  ##  SDL audio APIs assume you want this device ID.
  ##  ``openAudioDevice()`` calls always returns devices >= `2` on success.
  ##  The legacy calls are good both for backwards compatibility and when you
  ##  don't care about multiple, specific, or capture devices.

proc getNumAudioDevices*(iscapture: cint): cint {.
    cdecl, importc: "SDL_GetNumAudioDevices", dynlib: SDL2_LIB.}
  ##  Get the number of available devices exposed by the current driver.
  ##
  ##  Only valid after a successfully initializing the audio subsystem.
  ##  Returns `-1` if an explicit list of devices can't be determined; this is
  ##  not an error. For example, if SDL is set up to talk to a remote audio
  ##  server, it can't list every one available on the Internet, but it will
  ##  still allow a specific host to be specified to ``openAudioDevice()``.
  ##
  ##  In many common cases, when this function returns a value <= `0`,
  ##  it can still  successfully open the default device (`nil` for first
  ##  argument of ``openAudioDevice()``).

proc getAudioDeviceName*(index: cint; iscapture: cint): cstring {.
    cdecl, importc: "SDL_GetAudioDeviceName", dynlib: SDL2_LIB.}
  ##  Get the human-readable name of a specific audio device.
  ##
  ##  Must be a value between `0` and `(number of audio devices-1)`.
  ##  Only valid after a successfully initializing the audio subsystem.
  ##  The values returned by this function reflect the latest call to
  ##  ``getNumAudioDevices()``; recall that function to redetect available
  ##  hardware.
  ##
  ##  The string returned by this function is UTF-8 encoded, read-only, and
  ##  managed internally. You are not to free it. If you need to keep the
  ##  string for any length of time, you should make your own copy of it, as it
  ##  will be invalid next time any of several other SDL functions is called.

proc openAudioDevice*(
    device: cstring; iscapture: cint;
    desired: ptr AudioSpec; obtained: ptr AudioSpec;
    allowed_changes: cint): AudioDeviceID {.
      cdecl, importc: "SDL_OpenAudioDevice", dynlib: SDL2_LIB.}
  ##  Open a specific audio device.
  ##
  ##  Passing in a device name of `nil` requests the most reasonable default
  ##  (and is equivalent to calling ``openAudio()``).
  ##
  ##  The device name is a UTF-8 string reported by ``getAudioDeviceName()``,
  ##  but some drivers allow arbitrary and driver-specific strings, such as a
  ##  hostname/IP address for a remote audio server, or a filename in the
  ##  diskaudio driver.
  ##
  ##  ``Return`` `0` on error, a valid device ID that is >= `2` on success.
  ##
  ##  ``openAudio()``, unlike this function, always acts on device ID `1`.

type
  AudioStatus* {.size: sizeof(cint).} = enum
    AUDIO_STOPPED = 0,
    AUDIO_PLAYING,
    AUDIO_PAUSED

proc GetAudioStatus*(): AudioStatus {.
    cdecl, importc: "SDL_GetAudioStatus", dynlib: SDL2_LIB.}
  ##  Get the current audio state.

proc GetAudioDeviceStatus*(dev: AudioDeviceID): AudioStatus {.
    cdecl, importc: "SDL_GetAudioDeviceStatus", dynlib: SDL2_LIB.}
  ##  Get the current audio state.

proc pauseAudio*(pause_on: cint) {.
    cdecl, importc: "SDL_PauseAudio", dynlib: SDL2_LIB.}
  ##  Pause audio functions
  ##
  ##  These functions pause and unpause the audio callback processing.
  ##  They should be called with a parameter of `0` after opening the audio
  ##  device to start playing sound.  This is so you can safely initialize
  ##  data for your callback function after opening the audio device.
  ##  Silence will be written to the audio device during the pause.

proc pauseAudioDevice*(dev: AudioDeviceID; pause_on: cint) {.
    cdecl, importc: "SDL_PauseAudioDevice", dynlib: SDL2_LIB.}
  ##  Pause audio functions
  ##
  ##  These functions pause and unpause the audio callback processing.
  ##  They should be called with a parameter of `0` after opening the audio
  ##  device to start playing sound.  This is so you can safely initialize
  ##  data for your callback function after opening the audio device.
  ##  Silence will be written to the audio device during the pause.

proc loadWAV_RW*(
    src: ptr RWops; freesrc: cint; spec: ptr AudioSpec;
    audio_buf: ptr ptr uint8; audio_len: ptr uint32): ptr AudioSpec {.
      cdecl, importc: "SDL_LoadWAV_RW", dynlib: SDL2_LIB.}
  ##  This function loads a WAVE from the data source, automatically freeing
  ##  that source if ``freesrc`` is non-zero.  For example, to load a WAVE file,
  ##  you could do:
  ##
  ##      loadWAV_RW(rwFromFile("sample.wav", "rb"), 1, ...)
  ##
  ##
  ##  If this function succeeds, it returns the given AudioSpec,
  ##  filled with the audio data format of the wave data, and sets
  ##  ``audio_buf[]`` to a malloc()'d buffer containing the audio data,
  ##  and sets ``audio_len[]`` to the length of that audio buffer, in bytes.
  ##  You need to free the audio buffer with ``freeWAV()`` when you are
  ##  done with it.
  ##
  ##  This function returns `nil` and sets the SDL error message if the
  ##  wave file cannot be opened, uses an unknown data format, or is
  ##  corrupt.  Currently raw and MS-ADPCM WAVE files are supported.

template loadWAV*(file, spec, audio_buf, audio_len: expr): expr = ##  \
  ##  Loads a WAV from a file.
  ##
  ##  Compatibility convenience template.
  loadWAV_RW(rwFromFile(file, "rb"), 1, spec, audio_buf, audio_len)


proc freeWAV*(audio_buf: ptr uint8) {.
    cdecl, importc: "SDL_FreeWAV", dynlib: SDL2_LIB.}
  ##  This function frees data previously allocated with ``loadWAV_RW()``

proc buildAudioCVT*(cvt: ptr AudioCVT;
    src_format: AudioFormat; src_channels: uint8; src_rate: cint; 
    dst_format: AudioFormat; dst_channels: uint8; dst_rate: cint): cint {.
      cdecl, importc: "SDL_BuildAudioCVT", dynlib: SDL2_LIB.}
  ##  This function takes a source format and rate and a destination format
  ##  and rate, and initializes the ``cvt`` object with information needed
  ##  by ``convertAudio()`` to convert a buffer of audio data from one format
  ##  to the other.
  ##
  ##  ``Return`` `-1` if the format conversion is not supported,
  ##  `0` if there's no conversion needed, or 1 if the audio filter is set up.

proc convertAudio*(cvt: ptr AudioCVT): cint {.
    cdecl, importc: "SDL_ConvertAudio", dynlib: SDL2_LIB.}
  ##  Once you have initialized the ``cvt`` object using ``buildAudioCVT()``,
  ##  created an audio buffer ``cvt.buf``, and filled it with ``cvt.len`` bytes
  ##  of audio data in the source format, this function will convert it
  ##  in-place to the desired format.
  ##
  ##  The data conversion may expand the size of the audio data, so the buffer
  ##  ``cvt.buf`` should be allocated after the ``cvt`` object is initialized
  ##  by ``buildAudioCVT()``, and should be `cvt.len*cvt.len_mult` bytes long.

const
  MIX_MAXVOLUME* = 128

proc mixAudio*(dst: ptr uint8; src: ptr uint8; len: uint32; volume: cint) {.
    cdecl, importc: "SDL_MixAudio", dynlib: SDL2_LIB.}
  ##  This takes two audio buffers of the playing audio format and mixes
  ##  them, performing addition, volume adjustment, and overflow clipping.
  ##  The volume ranges from `0 - 128`, and should be set to `MIX_MAXVOLUME`
  ##  for full audio volume.  Note this does not change hardware volume.
  ##  This is provided for convenience -- you can mix your own audio data.

proc mixAudioFormat*(
    dst: ptr uint8; src: ptr uint8;
    format: AudioFormat; len: uint32; volume: cint) {.
      cdecl, importc: "SDL_MixAudioFormat", dynlib: SDL2_LIB.}
  ##  This works like ``mixAudio()``, but you specify the audio format instead
  ##  of using the format of audio device `1`.
  ##  Thus it can be used when no audio device is open at all.

proc lockAudio*() {.
    cdecl, importc: "SDL_LockAudio", dynlib: SDL2_LIB.}
  ##  Audio lock function.
  ##
  ##  The lock manipulated by these functions protects the callback function.
  ##  During a ``lockAudio()``/``unlockAudio()`` pair, you can be guaranteed
  ##  that the callback function is not running.  Do not call these from the
  ##  callback function or you will cause deadlock.

proc lockAudioDevice*(dev: AudioDeviceID) {.
    cdecl, importc: "SDL_LockAudioDevice", dynlib: SDL2_LIB.}
  ##  Audio lock function.
  ##
  ##  The lock manipulated by these functions protects the callback function.
  ##  During a ``lockAudio()``/``unlockAudio()`` pair, you can be guaranteed
  ##  that the callback function is not running.  Do not call these from the
  ##  callback function or you will cause deadlock.

proc unlockAudio*() {.
    cdecl, importc: "SDL_UnlockAudio", dynlib: SDL2_LIB.}
  ##  Audio unlock function.
  ##
  ##  The lock manipulated by these functions protects the callback function.
  ##  During a ``lockAudio()``/``unlockAudio()`` pair, you can be guaranteed
  ##  that the callback function is not running.  Do not call these from the
  ##  callback function or you will cause deadlock.

proc unlockAudioDevice*(dev: AudioDeviceID) {.
    cdecl, importc: "SDL_UnlockAudioDevice", dynlib: SDL2_LIB.}
  ##  Audio unlock function.
  ##
  ##  The lock manipulated by these functions protects the callback function.
  ##  During a ``lockAudio()``/``unlockAudio()`` pair, you can be guaranteed
  ##  that the callback function is not running.  Do not call these from the
  ##  callback function or you will cause deadlock.

proc closeAudio*() {.
    cdecl, importc: "SDL_CloseAudio", dynlib: SDL2_LIB.}
  ##  This function shuts down audio processing and closes the audio device.

proc closeAudioDevice*(dev: AudioDeviceID) {.
    cdecl, importc: "SDL_CloseAudioDevice", dynlib: SDL2_LIB.}
  ##  This function shuts down audio processing and closes the audio device.