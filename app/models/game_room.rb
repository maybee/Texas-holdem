class GameRoom
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :players
  has_many :rounds

  field :name, type: String
  field :max_players, type: Integer
  field :min_bet, type: Integer
  field :active, type: Boolean
  field :closed, type: Boolean
  field :isPrivate, type: Boolean

  default_scope -> { where(closed: false) }

  def self.new_room(params)
    self.create(params.merge!(active: false, closed: false))
  end

  def add_player(user)
    check = self.players.where(owner: user)

    if (check.count == 0)
      player = Player.new_player(user, 5000)
      self.players << player
      save
      Pusher.trigger("gameroom-#{id}", 'newplayer', player)
    end

    return self.players
  end

  def remove_player(user)
    player = Player.where(game_room: id, owner: user).first
    player.leave()
    Pusher.trigger("gameroom-#{id}", 'playerleft', player)
  end

  def close
    self.active = false
    save
  end

  def start
    if (!self.active && self.players.count >= 2)
      new_round
      self.active = true
      save
    end
  end

  def new_round
    new_blinds
    round = Round.new_round(self.players, self.min_bet)
    round.initialise
    self.rounds << round
    response = {players: self.players, newround: access_round}
    Pusher.trigger("gameroom-#{id}", 'newround', response)
    save
    round.start
  end

  def new_blinds
    last_big = false
    last_small = false

    self.players.each do |p|
      if(last_big)
        p.big_blind = true
        break
      end

      if(p.big_blind)
        p.big_blind = false
        last_big = true
      end
    end

    self.players.each do |p|
      if(last_small)
        p.small_blind = true
        break
      end

      if(p.small_blind)
        p.small_blind = false
        last_small = true
      end
    end

    if(!last_small && !last_big)
      self.players[0].small_blind = true
      self.players[1].big_blind = true
    end

    save
  end

  def access_round
    round = self.rounds
    response = {:round => round.without(:communal_cards).first, :cards => round.first.access_cards}
    return response
  end

  def buyInOk?(buy_in)
    return buy_in <= self.limit
  end

end


class BuyInExceedsLimitError < StandardError
end