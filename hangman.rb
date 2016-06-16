class Hangman
  attr_reader :guesser, :referee, :board
  
  def initialize(players)
  	@guesser = players[:guesser]
  	@referee = players[:referee]
    @turns_left = 8
  end

  def setup
    @board = Array.new(referee.pick_secret_word) {nil}
  	guesser.register_secret_length(board.length)
  end

  def take_turn
  	guess = guesser.guess(board) 
  	indices = referee.check_guess(guess)
  	update_board(guess, indices)
  	guesser.handle_response(guess, indices)
  end

  def update_board(guess, indices)
    indices.each { |i| @board[i] = guess }
  end

  def won?
    !board.include?(nil)
  end

  def play
    setup

    while @turns_left > 0
      take_turn
      @turns_left -= 1
      break if won?
    end

    if won?
      puts "You won with #{@turns_left} turns left, the word was #{@secret_word}" 
    else
      puts "You lost. The word was #{referee.secret_word}"
    end

  end

end

class HumanPlayer
  attr_reader :secret_word

  def pick_secret_word
    puts "What do you pick to be the secret word?"
    @secret_word = gets.chomp
  end

  def register_secret_length(length)
    puts "The secret word has #{length} characters"
  end

  def guess(board)
    p board
    puts "Guess a letter"
    gets.chomp
  end

  def check_guess(guess)
    (1...@secret_word.length).select { |i| @secret_word[i] == guess }
  end

  def handle_response(guess, indices)
    puts "#{guess} can be found at the following indices of the secret word #{indices}"
  end

end

class ComputerPlayer
  def self.computer_with_dictionary(dictionary_file)
    ComputerPlayer.new(File.readlines(dictionary_file).map(&:chomp))
  end

  attr_reader :dictionary, :secret_word, :candidate_words

  def initialize(dictionary)
  	@dictionary = dictionary
  end

  def pick_secret_word
    @secret_word = dictionary.sample
    secret_word.length  
  end

  def check_guess(letter)
    (0...secret_word.length).select { |i| secret_word[i] == letter }
  end

  def register_secret_length(length)
    @candidate_words = dictionary.select { |word| word.length == length }
  end

  def guess(board)
    valid_chars = freq_table.delete_if { |char, count| board.include?(char) }
    valid_chars.last[0]
  end
  
  def handle_response(letter, indices)
  	candidate_words.reject! do |word|
      remove = false
      indices.each { |i| remove = true if word[i] != letter }
      remove = true if word.count(letter) > indices.count
      remove = true if indices.empty? && word.include?(letter)

      remove
    end
  end

  private

  def freq_table
    freq_table = Hash.new(0)
    candidate_words.join("").each_char do |char|
      freq_table[char] += 1
    end
    freq_table.sort_by { |char, count| count }
  end

end

#have to run from lib to use the dictionary.txt file
if $PROGRAM_NAME == __FILE__
  puts "Do you want to guess or referee? Type \"guess\" or \"ref\""
  if gets.chomp == "guess"
    guesser = HumanPlayer.new
    referee = ComputerPlayer.computer_with_dictionary("dictionary.txt")
  elsif gets.chomp == "referee"
    referee = HumanPlayer.new
    guesser = ComputerPlayer.computer_with_dictionary("dictionary.txt")
  end

  Hangman.new(guesser: guesser, referee: referee).play
end
