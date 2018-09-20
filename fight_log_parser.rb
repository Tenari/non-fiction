#!/usr/bin/env ruby

def time_to_i(str)
  arr = str.split(':')
  (5*60) - (arr[0].to_i() *60) - (arr[1].to_i())
end
filename = ARGV[0]
lines = File.readlines(filename)
fighterA = lines[0].split(' = ').last
fighterB = lines[1].split(' = ').last

exchanges = []
current_exchange = {}
current_stance = nil
a_forward = nil
b_forward = nil
moves = {'A'=>[],'B'=>[]}
a_hit_or_sig_in_exchange = false
b_hit_or_sig_in_exchange = false

lines[2..-1].each do |line|
  if line == "===\n"
    moves.each do |actor_key, list|
      list.each do |move|
        move[:self_hit_during_exchange] = actor_key == 'A' ? a_hit_or_sig_in_exchange : b_hit_or_sig_in_exchange
      end
    end
    current_exchange[:moves] = moves.dup
    exchanges.push(current_exchange.dup) if current_exchange[:duration]
    moves = {'A'=>[],'B'=>[]}
    a_hit_or_sig_in_exchange = false
    b_hit_or_sig_in_exchange = false
    current_exchange = {
      start_time: nil,
      end_time: nil,
      duration: nil,
      initiator: nil,
      total_strikes: 0,
      total_feints: 0,
      misses: 0,
      glancing: 0,
      hits: 0,
      significant_hits: 0,
      initial_stance: nil, # open/closed
      moves: {'A'=> [], 'B'=> []} # move = {stance: 'open', forward: 'left', technique: 'turnK', target: 'knee', result: 'hit', response_result: 'miss', self_hit_during_exchange: false}
    }
    next
  end
  line_parts = line.split(' ')
  if line_parts[1] =~ /stance/
    current_stance = line_parts[1].gsub('_stance','')
    current_exchange[:initial_stance] ||= current_stance
    a_forward = line_parts[3]
    b_forward = line_parts[5]
  elsif ['A','B'].include?(line_parts[1])
    current_exchange[:start_time] ||= time_to_i(line_parts[0])
    current_exchange[:end_time] = time_to_i(line_parts[0])
    current_exchange[:duration] = (current_exchange[:end_time] - current_exchange[:start_time]) || 1
    current_exchange[:initiator] ||= line_parts[1]
    actor = nil
    line_parts[1..-1].each do |part|
      if ['A','B'].include?(part)
        actor = part
      else
        split_move = part.split('_')
        move = {
          stance: current_stance,
          forward: actor == 'A' ? a_forward : b_forward,
          technique: split_move[0],
          target: split_move[1],
          result: split_move[2],
        }
        if move[:technique] == 'feint'
          current_exchange[:total_feints] += 1
        end
        if move[:result]
          current_exchange[:misses] += 1 if move[:result] == 'miss'
          current_exchange[:glancing] += 1 if move[:result] == 'glance'
          current_exchange[:hits] += 1 if move[:result] == 'hit'
          current_exchange[:significant_hits] += 1 if move[:result] == 'significantHit'
          if ['hit','significantHit'].include?(move[:result])
            actor == 'A' ? b_hit_or_sig_in_exchange = true : a_hit_or_sig_in_exchange = true
          end
          current_exchange[:total_strikes] += 1
        end
        moves[actor].push(move)
      end
    end
  end
end

technique_stats = {}
result_stats = {}
exchanges.each do |exchange|
  exchange[:moves].each do |actor, moves|
    moves.each do |move|
      technique_stats[move[:technique]] ||= 0
      technique_stats[move[:technique]] += 1
      if move[:result]
        result_stats[move[:result]] ||= {}
        result_stats[move[:result]][move[:technique]] ||= 0
        result_stats[move[:result]][move[:technique]] += 1
      end
      puts "#{actor},#{move[:stance]},#{move[:forward]},#{move[:technique]},#{move[:target]},#{move[:result]},#{move[:self_hit_during_exchange]}"
    end
  end
end
puts "technique,misses,miss%,glance,glance%,hits,hit%,sigHit,sigHit%"
technique_stats.each do |technique, count|
  misses = result_stats['miss'][technique] || 0
  missP = misses.to_f / count
  glance = result_stats['glance'][technique] || 0
  glanceP = glance.to_f / count
  hits = result_stats['hit'][technique] || 0
  hitP = hits.to_f / count
  sigHits = result_stats['significantHit'][technique] || 0
  s_hitP = sigHits.to_f / count
  puts "#{technique},#{misses},#{missP},#{glance},#{glanceP},#{hits},#{hitP},#{sigHits},#{s_hitP}"
end
