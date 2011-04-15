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