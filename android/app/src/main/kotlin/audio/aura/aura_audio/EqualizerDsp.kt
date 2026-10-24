package audio.aura.aura_audio

import kotlin.math.*

data class EqConfig(val enabled: Boolean = true, val gains: DoubleArray = DoubleArray(10), val preamp: Double = 0.0)
object EqState { @Volatile var config = EqConfig() }

/** RBJ peaking filters, Q=1.4. No Flutter calls, locks, or per-sample allocations. */
class EqualizerDsp {
    companion object {
        val frequencies = doubleArrayOf(31.0, 62.0, 125.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0, 16000.0)
        fun coefficients(frequency: Double, gain: Double, sampleRate: Int): DoubleArray {
            if (frequency >= sampleRate * 0.5) return doubleArrayOf(1.0, 0.0, 0.0, 0.0, 0.0)
            val w = 2 * PI * frequency / sampleRate
            val a = 10.0.pow(gain / 40)
            val alpha = sin(w) / (2 * 1.4)
            val a0 = 1 + alpha / a
            return doubleArrayOf((1 + alpha * a) / a0, -2 * cos(w) / a0, (1 - alpha * a) / a0, -2 * cos(w) / a0, (1 - alpha / a) / a0)
        }
        fun headroom(config: EqConfig, sampleRate: Int = 48000) = if (config.enabled) config.gains.indices.sumOf { if (frequencies[it] < sampleRate * 0.5) max(0.0, config.gains[it]) else 0.0 } else 0.0
        fun response(config: EqConfig, sampleRate: Int = 48000): List<Double> = (0..159).map { i ->
            if (!config.enabled) 0.0 else {
                val maxFrequency = min(20000.0, sampleRate * 0.495)
                val f = 20 * (maxFrequency / 20).pow(i / 159.0)
                val w = 2 * PI * f / sampleRate
                var db = config.preamp - headroom(config, sampleRate)
                frequencies.forEachIndexed { n, center ->
                    val c = coefficients(center, config.gains[n], sampleRate)
                    val nr = c[0] + c[1] * cos(w) + c[2] * cos(2 * w)
                    val ni = -c[1] * sin(w) - c[2] * sin(2 * w)
                    val dr = 1 + c[3] * cos(w) + c[4] * cos(2 * w)
                    val di = -c[3] * sin(w) - c[4] * sin(2 * w)
                    db += 10 * log10(max(1e-20, (nr * nr + ni * ni) / (dr * dr + di * di)))
                }
                db
            }
        }
    }
    private var rate = 48000
    private var channels = 2
    private var z1 = Array(10) { DoubleArray(channels) }
    private var z2 = Array(10) { DoubleArray(channels) }
    private var current = Array(10) { coefficients(frequencies[it], 0.0, rate) }
    private var target = current.map { it.copyOf() }.toTypedArray()
    private var applied: EqConfig? = null
    private var volume = 1.0
    private var targetVolume = 1.0
    private var remaining = 0
    fun configure(sampleRate: Int, channelCount: Int) {
        rate = sampleRate; channels = channelCount
        z1 = Array(10) { DoubleArray(channels) }; z2 = Array(10) { DoubleArray(channels) }
        current = Array(10) { coefficients(frequencies[it], 0.0, rate) }
        target = current.map { it.copyOf() }.toTypedArray(); applied = null
        volume = 1.0; remaining = 0
    }
    fun update(config: EqConfig) {
        if (applied === config) return
        applied = config
        target = Array(10) { coefficients(frequencies[it], if (config.enabled) config.gains[it] else 0.0, rate) }
        targetVolume = if (config.enabled) 10.0.pow((config.preamp - headroom(config, rate)) / 20) else 1.0
        remaining = max(1, rate / 25)
    }
    fun frame() {
        if (remaining > 0) {
            for (b in 0..9) for (k in 0..4) current[b][k] += (target[b][k] - current[b][k]) / remaining
            volume += (targetVolume - volume) / remaining
            remaining--
        }
    }
    fun sample(input: Double, channel: Int): Double {
        var x = input * volume
        for (b in 0..9) {
            val c = current[b]
            val y = c[0] * x + z1[b][channel]
            z1[b][channel] = c[1] * x - c[3] * y + z2[b][channel]
            z2[b][channel] = c[2] * x - c[4] * y
            x = y
        }
        if (applied?.enabled == true && abs(x) > 0.95) {
            return sign(x) * (0.95 + 0.05 * tanh((abs(x) - 0.95) / 0.05))
        }
        return x.coerceIn(-1.0, 1.0)
    }
}
