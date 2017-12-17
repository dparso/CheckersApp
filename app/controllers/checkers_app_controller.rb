class CheckersAppController < ApplicationController
	protect_from_forgery with: :null_session

	# delete tells move if a capture has been made, in which case we need to update an extra square
	@@delete = []
	@@from = [-1, -1]

	#@@board = [[0, 1, 0, 1, 0, 1, 0, 1], [1, 0, 1, 0, 1, 0, 1, 0], [0, 1, 0, 1, 0, 1, 0, 1], [0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0], [2, 0, 2, 0, 2, 0, 2, 0], [0, 2, 0, 2, 0, 2, 0, 2], [2, 0, 2, 0, 2, 0, 2, 0]]

  	def index
  		puts "-----------In Index-----------"
  		@board = Board.all
  		if @board.size == 0
  			puts "Making new board!"
  			setBoard
  			@board = Board.all
  		end
  		puts "Current board = #{@board.size}"
  	end

  	def select 
  		puts "-----------In Select-----------"
  		@board = Board.all[0]

  		# fromRow = params[:fromRow]
  		# fromCol = params[:fromCol]
  		toRow = params[:toRow]
  		toCol = params[:toCol]

  		to = [toRow.to_i, toCol.to_i]

  		if @@from[0] > -1
  			# this is user's second click: make the move and reset @@from
  			if moveValid?(@@from, to, @board.turn.to_i)
  				move(@@from, to, @board.turn.to_i)

  				printBoard(boardFromString())
  			end
  			@@from = [-1, -1]
  		else
  			# this is user's first click: save validList and set @@from
  			@@from = [toRow.to_i, toCol.to_i]
  		end

  	# 	from = [fromRow.to_i, fromCol.to_i]
  	# 	to = [toRow.to_i, toCol.to_i]

 

  		# newBoard = "test"

  		# map = {"position" => newBoard, "turn" => newTurn}

	  	# newRow = Board.new(map)

	  	respond_to do |format|
	  		# if newRow.save # update instead?
	  			format.html{redirect_to "/"}
	  		# else
	  		# 	format.html{redirect_to "/"}
	  		# end
	  	end
	end

	def setBoard
		newTurn = 1
		# trailing 1's avoid misinterpreting numbers with trailing 0's (e.g., 01010101)
		map = {"turn" => newTurn, "row1" => "101010101", "row2" => "110101010", "row3" => "101010101", "row4" => "100000000", "row5" => "100000000", "row6" => "120202020", "row7" => "102020202", "row8" => "120202020", "validList" => ""}

		newRow = Board.new(map)
		if newRow.save
			puts "Saved new board!"
		else
			puts "Failed to save new board."
		end
	end

	def moveValid?(from, to, player, verbose=true)
		# make board from the database
		@board = Board.all[0]
		board = boardFromString

		# is it their move?
		if player.to_i != @board.turn.to_i
			if verbose
				puts "Not your turn!"
			end
			return false
		# in range?
		elsif not (from[0].between?(0, 7) and from[1].between?(0, 7) and to[0].between?(0, 7) and to[1].between?(0, 7))
			if verbose
				puts "Selected move out of range."
			end
			return false
		# is there a piece to start?
		elsif board[from[0]][from[1]].to_i == 0
			if verbose
				puts "Selected empty square!"
			end
			return false
		# is the current piece the player's?
		elsif board[from[0]][from[1]].to_i != player.to_i
			if verbose
				puts "That's not your piece!"
			end
			return false
		# is the end spot available?
		elsif board[to[0]][to[1]].to_i != 0
			if verbose
				puts "That spot is taken!"
			end
			return false
		end

		# can't move backwards
		if player.to_i == 1
			if to[0] - from[0] < 0
				if verbose
					puts "P1: You can't move backwards!"
				end
				return false
			end
		elsif player.to_i == 2
			if from[0] - to[0] < 0
				if verbose
					puts "P2: You can't move backwards!"
				end
				return false
			end
		end

		# is the move diagonal?
		$xDiff = to[0] - from[0]
		$yDiff = to[1] - from[1]
		if not $xDiff.abs == $yDiff.abs or $xDiff.abs > 2 or $yDiff.abs > 2
			if verbose
				puts "You must move diagonally."
			end
			return false
		# jumped a piece, then the piece in between must be the opponent's
		elsif $xDiff.abs == 2
			$xCoord = from[0] + ($xDiff / 2)
			$yCoord = from[1] + ($yDiff / 2)

			puts "You jumped over (#{$xCoord}, #{$yCoord})"

			if board[$xCoord][$yCoord].to_i == player.to_i
				if verbose
					puts "You can only jump over an opponent's piece."
				end
				return false
			end
			puts "Adding #{[$xCoord, $yCoord]}"
			@@delete += [$xCoord, $yCoord]
		end

		return true
	end

	def boardFromString()
		# returns a normal array of numbers based on the string representation of the database
		# note: all values will be strings!
		@board = Board.last
		board = []
		for i in 1..8
			name = "row" + i.to_s
			board[i - 1] = @board.send(:"#{name}").split("")
			board[i - 1].shift()
		end
		return board
	end

	def getValidSquares(index)
		# returns an array of all possible moves for a given square
		board = boardFromString
		player = Board.last.turn

		validMoves = []

		# a normal piece (not king) has only four moves: two single diagonals, and two jump diagonals
		for sign in -1..1
			if sign != 0
				for dist in 1..2
					if player == 1
						# alternates +/- 1, +/- 2
						to = [index[0] + 1, index[1] + sign * dist]
						if moveValid?(index, to, player, false)
							validMoves.push(to)
						end
					else
						to = [index[0] - 1, index[1] + sign * dist]
						if moveValid?(index, to, player, false)
							validMoves.push(to)
						end
					end
				end
			end
		end
		return validMoves
	end

	def setValue(index, value)
		# set a spot on the board to a certain value

		# in database, columns are row1, row2, etc. -- must increase by 1 to account for 0-based indexing
		name = "row" + (index[0] + 1).to_s
		row = @board.send(:"#{name}")
		puts "Inside first is #{row}"
		row[index[1] + 1] = value.to_s # + 1 for leading 1
		puts "Then is #{row}"
		@board.save
	end


	def move(from, to, player) 
		puts "BY THE WAY, possible moves for that piece were #{getValidSquares(from)}"
  		setValue(from, 0)
  		setValue(to, player)

  		# make any deletions specified by the moveValid method
  		if @@delete.size > 0
  			puts "Going to delete"
  			puts "Telling to delete (#{@@delete[0]}, #{@@delete[1]})"
  			setValue(@@delete, 0)
  			@@delete = []
  		end

  		# next player's turn
		@board.turn = @board.turn == 1 ? 2 : 1
  		@board.save
	end


	def printBoard(board)
		for i in 0...8
			for j in 0...8
				print "#{board[i][j]} "
			end
			puts
		end
	end

end


# TODO:
# just add a board instead of resetting
# highlight available squares!!!!!!!
# allow multiple jumps
