#!/usr/bin/env python
##################################################
# Gnuradio Python Flow Graph
# Title: Top Block
# Generated: Tue Jan  8 07:20:23 2013
##################################################

from gnuradio import digital
from gnuradio import eng_notation
from gnuradio import gr
from gnuradio import window
from gnuradio.eng_option import eng_option
from gnuradio.gr import firdes
from gnuradio.wxgui import fftsink2
from gnuradio.wxgui import forms
from grc_gnuradio import wxgui as grc_wxgui
from optparse import OptionParser
import wx

class top_block(grc_wxgui.top_block_gui):

	def __init__(self):
		grc_wxgui.top_block_gui.__init__(self, title="Top Block")
		_icon_path = "/usr/share/icons/hicolor/32x32/apps/gnuradio-grc.png"
		self.SetIcon(wx.Icon(_icon_path, wx.BITMAP_TYPE_ANY))

		##################################################
		# Variables
		##################################################
		self.squelch = squelch = -20
		self.samp_rate = samp_rate = 1e6

		##################################################
		# Blocks
		##################################################
		_squelch_sizer = wx.BoxSizer(wx.VERTICAL)
		self._squelch_text_box = forms.text_box(
			parent=self.GetWin(),
			sizer=_squelch_sizer,
			value=self.squelch,
			callback=self.set_squelch,
			label='squelch',
			converter=forms.float_converter(),
			proportion=0,
		)
		self._squelch_slider = forms.slider(
			parent=self.GetWin(),
			sizer=_squelch_sizer,
			value=self.squelch,
			callback=self.set_squelch,
			minimum=-99,
			maximum=0,
			num_steps=100,
			style=wx.SL_HORIZONTAL,
			cast=float,
			proportion=1,
		)
		self.Add(_squelch_sizer)
		self.wxgui_fftsink2_0 = fftsink2.fft_sink_c(
			self.GetWin(),
			baseband_freq=0,
			y_per_div=10,
			y_divs=10,
			ref_level=0,
			ref_scale=2.0,
			sample_rate=samp_rate,
			fft_size=1024,
			fft_rate=15,
			average=False,
			avg_alpha=None,
			title="FFT Plot",
			peak_hold=False,
		)
		self.Add(self.wxgui_fftsink2_0.win)
		self.low_pass_filter_0 = gr.fir_filter_ccf(1, firdes.low_pass(
			1, samp_rate, 150e3, 100e3, firdes.WIN_HAMMING, 6.76))
		self.gr_throttle_0 = gr.throttle(gr.sizeof_gr_complex*1, samp_rate)
		self.gr_sig_source_x_0 = gr.sig_source_c(samp_rate, gr.GR_COS_WAVE, 20e3, 1, 0)
		self.gr_quadrature_demod_cf_0 = gr.quadrature_demod_cf(1)
		self.gr_pwr_squelch_xx_0 = gr.pwr_squelch_cc(squelch, .1, 0, True)
		self.gr_multiply_xx_0 = gr.multiply_vcc(1)
		self.gr_file_source_0 = gr.file_source(gr.sizeof_gr_complex*1, "/home/samurai/Desktop/SamuraiSTFU-Course-Files/GNURadio/Xyloc Proximity Card/sample/xyloc-clip-1Msps-rtl.cfile", True)
		self.gr_file_sink_0 = gr.file_sink(gr.sizeof_char*1, "/tmp/bits")
		self.gr_file_sink_0.set_unbuffered(False)
		self.digital_correlate_access_code_bb_0 = digital.correlate_access_code_bb("0011001101010101", 0)
		self.digital_clock_recovery_mm_xx_0 = digital.clock_recovery_mm_ff(8, .008, 0, .175, .005)
		self.digital_binary_slicer_fb_0 = digital.binary_slicer_fb()

		##################################################
		# Connections
		##################################################
		self.connect((self.gr_throttle_0, 0), (self.gr_multiply_xx_0, 0))
		self.connect((self.gr_file_source_0, 0), (self.gr_pwr_squelch_xx_0, 0))
		self.connect((self.gr_pwr_squelch_xx_0, 0), (self.gr_throttle_0, 0))
		self.connect((self.low_pass_filter_0, 0), (self.gr_quadrature_demod_cf_0, 0))
		self.connect((self.gr_quadrature_demod_cf_0, 0), (self.digital_clock_recovery_mm_xx_0, 0))
		self.connect((self.digital_clock_recovery_mm_xx_0, 0), (self.digital_binary_slicer_fb_0, 0))
		self.connect((self.digital_binary_slicer_fb_0, 0), (self.digital_correlate_access_code_bb_0, 0))
		self.connect((self.digital_correlate_access_code_bb_0, 0), (self.gr_file_sink_0, 0))
		self.connect((self.gr_sig_source_x_0, 0), (self.gr_multiply_xx_0, 1))
		self.connect((self.gr_multiply_xx_0, 0), (self.low_pass_filter_0, 0))
		self.connect((self.low_pass_filter_0, 0), (self.wxgui_fftsink2_0, 0))


	def get_squelch(self):
		return self.squelch

	def set_squelch(self, squelch):
		self.squelch = squelch
		self._squelch_slider.set_value(self.squelch)
		self._squelch_text_box.set_value(self.squelch)
		self.gr_pwr_squelch_xx_0.set_threshold(self.squelch)

	def get_samp_rate(self):
		return self.samp_rate

	def set_samp_rate(self, samp_rate):
		self.samp_rate = samp_rate
		self.gr_sig_source_x_0.set_sampling_freq(self.samp_rate)
		self.low_pass_filter_0.set_taps(firdes.low_pass(1, self.samp_rate, 150e3, 100e3, firdes.WIN_HAMMING, 6.76))
		self.wxgui_fftsink2_0.set_sample_rate(self.samp_rate)

if __name__ == '__main__':
	parser = OptionParser(option_class=eng_option, usage="%prog: [options]")
	(options, args) = parser.parse_args()
	tb = top_block()
	tb.Run(True)

