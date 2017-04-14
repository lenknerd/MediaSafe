# ClientOnly_Test.rb
# Minitest tests pertaining to modules in MediaSafeClient.rb and a few shared ones
#
# David Lenkner, 2017

require 'minitest/autorun'


class TestMFileAction < Minitest::Test
	def setup
		@strvals = [
			'UNDECIDED',
			'SENT_KEPT',
			'SENT_DELD',
			'SKIP_KEPT',
			'SKIP_DELD',
			'akjkj2b4tjjbetk'
		]
		@intvals = [0,1,2,3,4,5]
	end

	def test_strs
		int_vals_calculated = @strvals.map { |x| MFileAction.fr_str(x) }
		assert_equal int_vals_calculated, @intvals
	end

	def test_ints
		str_vals_calculated = @intvals.map { |x| MFileAction.to_str(x) }
		assert_equal str_vals_calculated, @strvals[0..-2] + ['UNDEFINED']
	end
end


