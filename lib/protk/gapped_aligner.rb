require 'bio'
require 'matrix'

class PeptideFragment
	attr_accessor :start
	attr_accessor :end
	attr_accessor :seq
end

class GappedAligner

	

	@big_penalty
	@gap_open_penalty
	@gap_extend_penalty

	def initialize
		@big_penalty = -100000
		@gap_open_penalty = -10
		@gap_extend_penalty = -1
		@end_gap_penalty = 0
		@match_move=0
		@aadel_move=-1
		@nadel_move=1
	end

	def aa_deletion()
		return @big_penalty
	end

	def na_deletion(move_type)
		if move_type==@nadel_move
			return @gap_extend_penalty
		end
		return @gap_open_penalty
	end

	def score_match(aa,na)
		if aa==na
			return 1			
		end
		return @big_penalty
	end

	def traceback(from_row,from_col,dpmoves)
		last_move = dpmoves[from_row][from_col]
		last_row = from_row-1
		last_col = from_col-1
		if last_move==@aadel_move
			last_col+=1
		elsif last_move==@nadel_move			
			last_row+=1
		end
#		puts "#{last_row},#{last_col}"
		if last_col==0 && last_row==0
			return [last_move]
		else
#			require 'debugger';debugger

			throw "Beyond end of array" if last_col<0 || last_row <0

			return traceback(last_row,last_col,dpmoves).push(last_move)
		end
#		result
	end


	def calculate_dp(pep_seq,gene_seq)
		nrow = pep_seq.length+1
		ncol = gene_seq.length+1

		throw "Peptide sequence is longer than gene" if nrow > ncol


		dpmoves=Matrix.build(nrow,ncol) {|r,c| 0 }
		dpmatrix=Matrix.build(nrow,ncol) { |r,c| 0 }
		dpmatrix = dpmatrix.to_a
		dpmoves = dpmoves.to_a

		# Boundary conditions
		(0..(nrow-1)).each { |i| 
			dpmatrix[i][0] = aa_deletion*i 
			dpmoves[i][0] = @aadel_move
		}
		(0..(ncol-1)).each { |j| 
			dpmatrix[0][j] = @end_gap_penalty*j 
			dpmoves[0][j] = @nadel_move
		}
		dpmoves[0][0]=0

		(1..(nrow-1)).each do |i|
			(1..(ncol-1)).each do |j|
				aa = pep_seq[i-1]
				na = gene_seq[j-1]

				match = score_match(aa,na) + dpmatrix[i-1][j-1]

				nadel = na_deletion(dpmoves[i][j-1]) + dpmatrix[i][j-1]

				if match >= nadel
					dpmatrix[i][j] = match					
					dpmoves[i][j] = @match_move
				else
					dpmatrix[i][j] = nadel
					dpmoves[i][j] = @nadel_move
				end

			end
		end
		require 'debugger';debugger
		traceback(nrow-1,ncol-1,dpmoves)
	end


	def align pep_seq, gene_seq
		# Against "ABCDEFGHI"
		pep_seq="CDE"
		pep_seq="CFGH" #Expect [1,1,0,1,1,0,0,0,1]

		trace = calculate_dp(pep_seq,gene_seq)
		require 'debugger';debugger

		return [PeptideFragment.new(),PeptideFragment.new()]
	end

end