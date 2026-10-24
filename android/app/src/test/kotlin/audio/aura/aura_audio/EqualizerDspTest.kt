package audio.aura.aura_audio

import org.junit.Assert.*
import org.junit.Test
import kotlin.math.*

class EqualizerDspTest {
    private fun measured(frequency: Double, config: EqConfig, channel: Int = 0): Double {
        val dsp = EqualizerDsp(); dsp.configure(48000, 2); dsp.update(config)
        var energy = 0.0
        for (i in 0 until 48000) {
            dsp.frame()
            val input = .1 * sin(2 * PI * frequency * i / 48000)
            val out = dsp.sample(input, channel)
            // Exercise independent silent channel state as well.
            val silent = dsp.sample(0.0, 1 - channel)
            assertEquals(0.0, silent, 1e-9)
            assertTrue(out.isFinite())
            if (i >= 24000) energy += out * out
        }
        return sqrt(energy / 24000)
    }
    @Test fun flatAndBypassPreserveSignal() {
        val flat = measured(1000.0, EqConfig())
        assertEquals(.1 / sqrt(2.0), flat, 1e-6)
        assertEquals(flat, measured(1000.0, EqConfig(false, DoubleArray(10) { 12.0 }, -12.0)), 1e-6)
    }
    @Test fun bassGainReallyChangesFrequencyBalance() {
        val config = EqConfig(true, doubleArrayOf(0.0, 9.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0))
        val low = measured(62.0, config)
        val high = measured(8000.0, config)
        assertTrue("62Hz boost must affect PCM, not just UI", low / high > 2.7)
    }
    @Test fun preampReallyChangesLevel() {
        val a = measured(1000.0, EqConfig(preamp = 6.0))
        val b = measured(1000.0, EqConfig(preamp = 0.0))
        assertEquals(6.0, 20 * log10(a / b), .02)
    }
    @Test fun graphMatchesActualFilterResponse() {
        val config = EqConfig(true, doubleArrayOf(2.0, 3.0, 1.0, -2.0, -1.0, 0.0, 2.0, 0.0, -1.0, 1.0), -2.0)
        val curve = EqualizerDsp.response(config)
        for (index in listOf(20, 60, 90, 130)) {
            val frequency = 20 * 1000.0.pow(index / 159.0)
            val actual = 20 * log10(measured(frequency, config) / (.1 / sqrt(2.0)))
            assertEquals(curve[index], actual, .08)
        }
    }
    @Test fun boostsHaveHeadroomAndSmoothFiniteTransitions() {
        val dsp = EqualizerDsp(); dsp.configure(44100, 2)
        val config = EqConfig(true, DoubleArray(10) { 12.0 }, 12.0)
        assertEquals(120.0, EqualizerDsp.headroom(config), 0.0)
        for (i in 0..9999) {
            if (i % 1000 == 0) dsp.update(if (i % 2000 == 0) config else EqConfig(false))
            dsp.frame()
            val out = dsp.sample(.9 * sin(i * .2), 0)
            assertTrue(out.isFinite() && abs(out) <= 1.0)
        }
    }
    @Test fun highBandsAreUnavailableRatherThanRetunedAtLowSampleRates() {
        val coefficients = EqualizerDsp.coefficients(16000.0, 12.0, 22050)
        assertArrayEquals(doubleArrayOf(1.0, 0.0, 0.0, 0.0, 0.0), coefficients, 0.0)
        val gains = DoubleArray(10); gains[9] = 12.0
        assertEquals(0.0, EqualizerDsp.headroom(EqConfig(gains = gains), 22050), 0.0)
    }
}
