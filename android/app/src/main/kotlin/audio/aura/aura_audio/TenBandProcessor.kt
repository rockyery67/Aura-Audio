package audio.aura.aura_audio

import androidx.media3.common.C
import androidx.media3.common.audio.AudioProcessor
import androidx.media3.common.audio.BaseAudioProcessor
import androidx.media3.common.util.UnstableApi
import java.nio.ByteBuffer
import kotlin.math.roundToInt

@UnstableApi
class TenBandProcessor : BaseAudioProcessor() {
    private val dsp = EqualizerDsp()
    @Volatile var processedFrames: Long = 0
        private set
    @Volatile var appliedConfig: EqConfig? = null
        private set
    var sampleRate = 48000
        private set
    override fun onConfigure(input: AudioProcessor.AudioFormat): AudioProcessor.AudioFormat {
        if (input.encoding != C.ENCODING_PCM_16BIT) throw AudioProcessor.UnhandledAudioFormatException(input)
        sampleRate = input.sampleRate
        return input
    }
    override fun onFlush(streamMetadata: AudioProcessor.StreamMetadata) { dsp.configure(inputAudioFormat.sampleRate, inputAudioFormat.channelCount) }
    override fun queueInput(input: ByteBuffer) {
        val output = replaceOutputBuffer(input.remaining())
        val configuration = EqState.config
        dsp.update(configuration)
        appliedConfig = configuration
        val channels = inputAudioFormat.channelCount
        processedFrames += input.remaining() / (channels * 2)
        while (input.remaining() >= channels * 2) {
            dsp.frame()
            for (c in 0 until channels) {
                val sample = dsp.sample(input.short / 32768.0, c)
                output.putShort((sample * 32767).roundToInt().coerceIn(-32768, 32767).toShort())
            }
        }
        output.flip()
    }
}
