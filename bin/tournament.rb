require "YAML"

class Match
  attr_reader :bots
  attr_reader :seed
  attr_reader :match
  
  def initialize(data)
    @bots = data['robots']
    @seed = data['seed']
    @ticks= data['elapsed_ticks']
    @timedout = data['timedout']
    @match = data['match']
  end
  
  def winner
    sorted = @bots.sort{|a,b| a[1]['damage_given'] <=> b[1]['damage_given']}
    return sorted[1][0]
  end

  def loser
    sorted = @bots.sort{|a,b| a[1]['damage_given'] <=> b[1]['damage_given']}
    return sorted[0][0]
  end
  
  def tie?
    return margin == 0.0 
  end
  
  def margin
    @bots[winner]['damage_given'] - @bots[loser]['damage_given']
  end
  
  def winner_points
    return 0.5 if simul?
    return winner_health / (winner_health + loser_health)
  end
  
  def loser_points
    return 0.5 if simul?
    return loser_health / (winner_health + loser_health)
  end
  
  def simul?
    winner_health + loser_health == 0
  end
  
  def timedout?
    @timedout == 1
  end
  
  #between 100 and 0
  def winner_health 
    [100 - @bots[winner]['damage_taken'], 0].max
  end
  
  #between 100 and 0
  def loser_health 
    [100 - @bots[loser]['damage_taken'], 0].max
  end
  
  def one_line_summary
    if !tie?
      line = "#{winner} beats #{loser} by #{'%.1f' % margin} energy in #{@ticks} ticks"
      if @timedout then line += " (match timed out, so #{winner} gets #{winner_points}, loser gets #{loser_points})" end
    else
      line = "#{winner} ties #{loser} at #{'%.1f' % winner_health} energy in #{@ticks} ticks"
      if @timedout then line += " (match timed out.)" end
    end
    line += " (timed out)" if @timeout
    return line
  end
end


class Round
  attr_accessor :matches
  attr_accessor :winner
  #attr_accessor :total_margin
  attr_reader :bots
  
  # matches should be an array of Matches
  def initialize (matches)
    @matches = matches
    @bots = Hash.new {|h,key| h[key] = {}}
    
    both_bots =  [@bots[@matches[0].winner], @bots[@matches[0].loser]]
    stats_to_init = ['wins', 'points', 'ties', 'margin', 'simul', 'timedout', 'round_wins']
    stats_to_init.each {|stat| both_bots.each {|b| b[stat] = 0 }}
    
    @matches.each do |match|
      @bots[match.winner]['points'] += match.winner_points
      @bots[match.loser]['points'] += match.loser_points
      both_bots.each {|b| b['ties'] += 1 if match.tie?}
      both_bots.each {|b| b['timedout'] += 1 if match.timedout?}
      both_bots.each {|b| b['simul'] += 1 if match.simul?}
      @bots[match.winner]['margin'] += match.margin
      if match.tie?
        both_bots.each {|b| b['wins'] += 0.5}
      else
        @bots[match.winner]['wins'] += 1
      end
      if both_bots[0]['wins'] > both_bots[1]['wins'] then both_bots[0]['round_wins'] = 1 end
      if both_bots[1]['wins'] > both_bots[0]['wins'] then both_bots[1]['round_wins'] = 1 end
      if both_bots[1]['wins'] == both_bots[0]['wins'] then both_bots[0]['round_wins'] = 0.5 ;both_bots[1]['round_wins'] = 0.5 end
    end
  end
  
  def winner
    sorted = @bots.sort{|a,b| a[1]['wins'] <=> b[1]['wins']}
    return sorted[1][0]
  end
  
  def loser
    sorted = @bots.sort{|a,b| a[1]['wins'] <=> b[1]['wins']}
    return sorted[0][0]
  end
  
  def tie?
    @bots[winner]['wins'] == @bots[loser]['wins']
  end
  #calc how many points for losing bot
  
  def one_line_summary
    if !tie?
      line = "#{winner} conquers #{loser} (#{@bots[winner]['wins']} to #{@bots[loser]['wins']} )"
    else
      line = "#{winner} ties #{loser} (#{@bots[winner]['wins']} to #{@bots[loser]['wins']} )"
    end
  end
end

def print_header(html)
  header = '''  
  <html>
  <head> <title>RRobots Tournament Results </title>
  <style type="text/css">
  <!--
    body, p{font-family: verdana, arial, helvetica, sans-serif; font-size: 12px;}
    table{background-color:white;	border:none;	padding:0px;	font-size: 12px;}
    tr{}
    td {
      background-color:#efefef;
      border-left:white 1px solid;
      border-top:white 1px solid;
      border-right:white 1px solid;
      border-bottom:white 1px solid;
      margin:0px;
      padding:4px;
    }
    td.sum {font-weight:bold;}
    td.blank {background-color:white}	
  -->
  </style>	
  </head>
  <body>
  '''
html.print(header)
end

def print_footer(html)
  footer = '''
  </body>
  </html>
  '''
  html.print(footer)
end

def rank_by_round_stat(stat, rounds)
  bots = Hash.new {|h,k| h[k] = 0}
  rounds.each do |round|
    bots[round.winner] += round.bots[round.winner][stat]
    bots[round.loser] += round.bots[round.loser][stat]
  end
  sorted = bots.sort {|a,b| b[1] <=> a[1]}
  return sorted
end

# print a html page with a table containing once cell per round
# include  stat in that cell.  if r is the round in question 
# then r.bots[current_bot][stat] had better exist!
def print_round_table(stat, rounds, ranking, round_tables, html)
  #ranking is an array of 2 element arrays - we just want the first element in the 'sub' array,
  # which is the robot name
  rows = ranking.collect {|a| a[0]}
  cols = rows.clone

  html.puts "<hr style='width: 100%; height: 2px;'>"
  html.puts"<a name='#{stat}'></a>"
  html.puts "<h1>#{stat}</h1>"
  html.puts "<table>"
  html.puts "<th>"
  cols.each {|col| html.puts "<td> #{col[0..2]} </td>"}
  html.puts "<td class='sum'>Sum</td></th>"
  rows.each do |row|
    html.puts "  <tr>"
    html.puts "  <td> #{row} </td> "
    row_total = 0
    cols.each do |col|
      round = nil
      if row != col
        round = rounds.find {|x| x.bots.has_key?(row) and x.bots.has_key?(col)}
        if round == nil then puts "couldn't find round bewtween #{row} and #{col}" end
        html.puts "    <td> #{ '%.1f'% round.bots[row][stat] } </td>"
        row_total += round.bots[row][stat]
      else  
        html.puts"    <td> --- </td>"
      end
    end
    html.puts "<td class='sum'> #{'%.1f'% row_total}</td>"
    html.puts "  </tr>"
  end
  html.puts "</table>"
end

def print_index(round_tables, rankings, stats, html)
  html.puts"<a name='top'></a>"
  html.puts "<h1> Round Summary Tables </h1>"
  html.puts "<ul>"
  
  round_tables.each { |t| html.puts "<li><a href='##{t}'>#{t}</a></li>"  }
  
  html.puts "</ul>"
  html.puts "<h1> Rankings</h1>"
  html.puts "<table><tr>"
  
  stats.each do |stat|
    html.puts "<td>#{stat}<table>"
    list = rankings[stat]
    list.each {|row| html.puts "<tr><td>#{row[0]}</td> <td> #{'%.1f'%row[1]}</td></tr>"}
    
    html.puts "</table></td>"
  end
  
  html.puts "</tr></table>"
  
  html.puts <<ENDHTML
  <h1>Definitions:</h1>
    <ul>
      <li>  Wins:  The numer of matches (battles) won by a robot.  (ties or timeouts earn both bots 0.5)</li>
      <li>  Points:  Similar to wins, but timeouts earn bots points proportional to their amount of health.  There is a chance this doesn't work properly yet</li>
      <li>  Round_wins:  Number of rounds won by a robot.  Indicates how many robots this robot can beat.  Ties earn 0.5 </li>
      <li>  Margin:  The margin of one match is how much energy the winning robot won by</li>
      <li>  Simul:  Number of times a robot was involved in Simultaneous deaths</li>
      <li>  Timedout:  Number of times a robot was in a match that timed out</li>
      <li>  Ties:  Number of matches a robot was in that ended in a tie </li>
    </ul>
ENDHTML
  print_footer(html)
end

def to_html match_data, html
	print_header(html)
	
	round_matches = Hash.new {|h,k| h[k] = []}
	robots = []
	
	match_data.each do |m|
	  match = Match.new(m)
	  round_matches[m['round']] << match
	  robots << match.winner
	  robots << match.loser
	end
	robots = robots.uniq
	
	rounds = []
	round_matches.values.each do |matches|
	  r = Round.new(matches)
	  rounds << r
	end
	
	stats = ['wins', 'points','round_wins', 'margin', 'simul', 'timedout', 'ties']
	rankings = {}
	stats.each{|stat| rankings[stat] = rank_by_round_stat(stat, rounds)}
	
	print_index(stats, rankings, stats, html) #pass stats array in insted of using rankings.keys so we can preserve order
	stats.each {|stat|  print_round_table(stat, rounds, rankings[stat],stats, html) }
	print_footer(html)
	html.close
end

####################################################################
# Main
####################################################################

def usage
  puts "Usage: ruby tournament.rb [-timeout=<N>] [-matches=<N>] (-dir=<Directory> | <RobotClassName[.rb]>+)"
  puts "\t[-timeout=<N>] (optional, default 10000) number of ticks a match will last at most."  
  puts "\t[-matches=<N>] (optional, default 2) how many times each robot fights every other robot."  
  puts "\t-dir=<Directory> All .rb files from that directory will be matched against each other."  
  puts "\tthe names of the rb files have to match the class names of the robots."
  exit(0)
end

#look for timeout arg
timeout = 10000
ARGV.grep( /^-timeout=(\d+)/ )do |item|
  timeout = $1.to_i
  ARGV.delete(item)
end

matches_per_round = 2
ARGV.grep( /^-matches=(\d+)/ )do |item|
  matches_per_round = $1.to_i
  ARGV.delete(item)
end

folder = '.'
robots = ARGV
ARGV.grep( /^-dir=(.+)$/ )do |item|
  begin
    folder = $1
    pwd = Dir.pwd
    Dir.chdir(folder)
    robots = Dir.glob('*.rb')
    Dir.chdir(pwd)
    ARGV.delete(item)
  rescue Exception
    puts "can't change directory to '#{folder}'"
    exit(0)
  end
end

ARGV.grep( /^-(.*)$/ )do |item|
  puts "Unknown option '-#{$1}'"
  puts
  usage
end

usage if robots.length <= 1
$stdout.sync = true

suffix=0
while File.exists?('tournament'  + suffix.to_s.rjust(2, '0') + '.yml')
  suffix = suffix + 1
end
results_file = 'tournament'  + suffix.to_s.rjust(2, '0') + ".yml"

rounds = []
round_number = 0
opponents = robots.clone
@all_match_data = []
robots.each do |bot1|
	
  opponents.delete bot1
  opponents.each do |bot2|
    round_number += 1
    puts
    puts "===== Round #{round_number}:   #{bot1} vs  #{bot2}   ====="
    i = 1
    matches = []
    matches_per_round.times do |i|
      puts "- Match #{i+1} of #{matches_per_round} -"
      cmd = "ruby rrobots.rb -nogui -timeout=#{timeout} #{folder}/#{bot1} #{folder}/#{bot2}"
      
      # using popen instead of `cmd` lets us see the progress dots (......) output as the match progresses.
      sub = IO.popen(cmd)
      results_string = sub.read
      sub.close

      match_data = YAML.load(results_string)
      match_data['match'] = i
      match_data['round'] = round_number
      match_data['timedout'] = 1 if timeout <= match_data['elapsed_ticks']
      @all_match_data << match_data
      
      match = Match.new(match_data)
      puts
      puts match.one_line_summary
      matches << match
    end
    rounds << Round.new(matches)
  end
end

# write out match results to a file for possible later analysis
File.open(results_file, 'w').puts(YAML::dump(@all_match_data))
to_html(@all_match_data, File.open(results_file.sub(/\..*$/, '.html'), 'w'))

puts
puts
puts "####################################################################"
puts "                     TOURNAMENT SUMMARY"
puts "####################################################################"
round_results = []
rounds.each {|round| round_results << round.one_line_summary}
round_results = round_results.sort
round_results.each {|r| puts r}


