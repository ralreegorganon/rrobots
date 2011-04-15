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