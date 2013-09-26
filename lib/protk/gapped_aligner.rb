require 'bio'
require 'matrix'

class PeptideFragment
	attr_accessor :start
	attr_accessor :end
	attr_accessor :seq
end

class PeptideToGeneAlignment
	attr_accessor :gene_seq
	attr_accessor :pep_seq
	attr_accessor :trace

	def initialize(gene,peptide,trace)
		@gene_seq = gene
		@pep_seq = peptide
		@trace = trace
	end

	def inspect
		descr = "#{@gene_seq}\n"

		pep_triples=""
		@pep_seq.each_char { |c| pep_triples<<c;pep_triples<<c;pep_triples<<c }
		
		# gene_seq_triples=""
		# Bio::Sequence::NA.new(@gene_seq).translate.each_char do |c| 
		# 	gene_seq_triples<<c;gene_seq_triples<<c;gene_seq_triples<<c 
		# end

		# descr << "#{gene_seq_triples}\n"
		
		pepi=0
		@trace.each_with_index do |move, i|  
			if move==1
				descr<<"-"
			elsif move==0
				descr<<"#{pep_triples[pepi]}"
				pepi+=1
			end
		end
		descr<<"\n"
		puts descr
	end

	def fragments
		frags=[]
		in_fragment=false
		@trace.each_with_index do |move,i|
			if move==0
				frags << [i,0] unless in_fragment #Start a fragment
				in_fragment=true	
			else
				frags.last[1]=i-1 if in_fragment #End a fragment
				in_fragment=false
			end					
		end
		if frags.last[1]==0
			frags.last[1]=@trace.length-1
		end
		frags
	end

	def gaps
		gps=[]
		in_start_end=true
		in_gap=false
		@trace.each_with_index do |move, i| 
			if move==0
				in_start_end=false
				if in_gap #Ending a gap
					gps.last[1]=i
				end
				in_gap=false
			else
				if !in_start_end && !in_gap #Starting a gap
					in_gap=true
					gps<<[i,0]
				end
			end				
		end
		#Remove gaps that have zero length (Trailing)
		gps=gps.collect do |gp| 
			rv=gp
			if gp[1]==0
				rv=nil
			end		
			rv
		end
		gps.compact!
		gps
	end

end

# Uses a dynamic programming algorithm (Smith-Waterman like) to align a peptide sequence to a nucleotide.
# This aligner assumes you are doing protogenomics and just want to assume that
#    (a) The entire peptide sequence matches (with gaps) to the DNA sequence
#
class GappedAligner

	def initialize
		@big_penalty = -1000000000
		@gap_open_penalty = -10000
		@gap_extend_penalty = -1
		@end_gap_penalty = 0
		@match_bonus = 400

		@match_move=0
		@aadel_move=-1
		@nadel_move=1
		@triplet_offsets = [[0,-2,-1],[-1,0,-2],[-2,-1,0]]
	end

	def aa_deletion()
		return @big_penalty
	end

	def score_na_deletion(move_type)
		if move_type==@nadel_move
			return @gap_extend_penalty
		end
		return @gap_open_penalty
	end

	def score_match(aa,na)
		if aa==na
			return @match_bonus		
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

		if last_col==0 && last_row==0
			return [last_move]
		else
			throw "Beyond end of array" if last_col<0 || last_row <0

			return traceback(last_row,last_col,dpmoves).push(last_move)
		end
	end

	def next_frame(previous_frame)
		(previous_frame+1) % 3
	end

	def translate_na_at(j,frame,gene_seq)
		rm = j % 3 
		start_pos=j+@triplet_offsets[rm][frame]
		if start_pos < 0
			return '-'
		else
			return gene_seq[start_pos,3].translate
		end
	end

	def save_matrix(dpmatrix,pep_triples,gene_seq,name)
		matfile=File.open("#{name}.csv", "w+")
		matfile.write(",,")
		gene_seq.each_char { |na| matfile.write("#{na},")  }
		matfile.write("\n")
		dpmatrix.each_with_index { |row,ri|  
			if ri>0
				matfile.write("#{pep_triples[ri-1]},")
			else
				matfile.write(",")
			end
			row.each { |col|  
				matfile.write("#{col},")
			}
			matfile.write("\n")
		}
		matfile.close()
	end

	def calculate_dp(pep_seq,gene_seq)
		gene_seq = Bio::Sequence::NA.new(gene_seq)
		nrow = pep_seq.length*3+1
		ncol = gene_seq.length+1

		throw "Peptide sequence is longer than gene" if nrow > ncol

		pep_triples=""
		pep_seq.each_char { |c| pep_triples<<c;pep_triples<<c;pep_triples<<c }

		dpmoves=Matrix.build(nrow,ncol) {|r,c| 0 }.to_a
		dpmatrix=Matrix.build(nrow,ncol) { |r,c| 0 }.to_a
		dpframes=Matrix.build(nrow,ncol) { |r,c| 0 }.to_a
		# before_gap_positions = Matrix.build(nrow,ncol) { |r,c| 0 }.to_a

		# Boundary conditions
		(0..(nrow-1)).each { |i| 
			dpmatrix[i][0] = aa_deletion*i 
			dpmoves[i][0] = @aadel_move
		}
		(0..(ncol-1)).each { |j| 
			dpmatrix[0][j] = @end_gap_penalty*j 
			dpmoves[0][j] = @nadel_move
			dpframes[0][j] = j % 3
		}
		dpmoves[0][0]=0
		dpframes[0][0]=0

		(1..(nrow-1)).each do |i|
			(1..(ncol-1)).each do |j|
				aa = pep_triples[i-1]

				translated_na = translate_na_at(j-1,dpframes[i-1][j-1],gene_seq)

				match = score_match(aa,translated_na) + dpmatrix[i-1][j-1]

				nadel = score_na_deletion(dpmoves[i][j-1]) + dpmatrix[i][j-1]

				# if (translated_na=="R") && (pep_seq=="FR") && (aa == "R")
					# require 'debugger';debugger					
				# end

				if match >= nadel
					dpmatrix[i][j] = match					
					dpmoves[i][j] = @match_move
					dpframes[i][j] = dpframes[i-1][j-1]
				else
					dpmatrix[i][j] = nadel
					dpmoves[i][j] = @nadel_move
					dpframes[i][j] = next_frame(dpframes[i][j-1])
				end

			end
		end

		# Find best end-point
		end_score = dpmatrix[nrow-1].max
		end_j = dpmatrix[nrow-1].index(end_score)

		save_matrix(dpmatrix,pep_triples,gene_seq,"dpmatrix")
		save_matrix(dpmoves,pep_triples,gene_seq,"moves")
		save_matrix(dpframes,pep_triples,gene_seq,"frames")
#		require 'debugger';debugger

		traceback(nrow-1,end_j,dpmoves)
	end


	def align pep_seq, gene_seq

		trace = calculate_dp(pep_seq,gene_seq)
		alignment = PeptideToGeneAlignment.new(gene_seq,pep_seq,trace)
		# puts alignment
		# require 'debugger';debugger

		return alignment
	end

end