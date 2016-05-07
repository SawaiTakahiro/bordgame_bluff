#! ruby -Ku

=begin
 2016/05/07
 
 ブラフ
=end


##########################################################################################
#共通の部分
require "fileutils"
require "CSV"
require "json"


#設定の読み込み
require "dotenv"
Dotenv.load

#自作汎用ライブラリはその後読む
require ENV["PATH_MY_LIBRARY"]

##########################################################################################
DICE_MAX = 5	#初期のサイコロは５個


class Game
	attr_reader :game_scene
	
	GAME_START = 0
	def initialize(player_num)
		@game_scene = GAME_START
		@status = {total: 0, dice: 0, num: 0}
		
		#プレイヤー作る
		@players = Array.new
		player_num.times do
			@players << Player.new
			@status[:total] += DICE_MAX
		end
		
		p "ゲーム作ったよ"
	end
	
	def get_scene
		#p @game_scene
	end
	
	#毎ターン呼んで使う
	def progress_game
		p "*"*20, "ゲームを進めるよ"
		
		#存在するプレイヤーの分だけ繰り返していく
		@players.each do |player|
			@status = player.play_turn(@status)
		end
		
	end
	
end

class Player
	attr_reader :dice_num, :hand
	
	@@player_num = 0
	
	def initialize
		@dice_num = DICE_MAX
		@hand = get_hand(@dice_num)
		
		#名前は適当。とりあえずつけておかないとテストしにくいので
		list_name = ["ramen", "curry", "yakisoba", "tenpura", "motsuni", "nikudoufu"]
		@name = list_name[@@player_num]
		
		@@player_num += 1
		
		p "playerクラス作ったよ。今のプレイヤー数は、#{@@player_num}人だよ"
	end
	
	def get_hand(dice_num)
		hand = Array.new
		
		dice_num.times{ hand << rand(1..6) }
		
		return hand.sort
	end
	
	def get_status
		p "これは#{@name}さんだよ。"
		p "手は、#{@hand}だよ", "*"*20
	end
	
	#ベットの吊り上げ処理。中身が合っているかも判定する
	def raise_a_bet(status)
		print "		ベットの吊り上げ\n"
		total	= status[:total]
		dice	= status[:dice]
		num		= status[:num]
		
		flag = false
		
		#正しい中身になるまで抜けない
		while flag != true do
			#ユーザに入力させる
			new_dice	= rand(1..6)
			new_num		= rand(num..num + 1)
			
			
			#あからさまにダメなら、そこで弾く
			#サイコロの目が不正 or 場の全部より多い指定
			if new_dice > 6 || new_num > total then
				print "		***違うのでやり直し\n"
				next
			end
			
			#場に出ている数より多く指定していたら、とりあえずOK
			if new_num > num
				print "		数の吊り上げ\n"
				num = new_num
				
				flag = true
				next
			end
			
			#同じ数だったとしても、目の数字が大きくなっていればOK
			if new_dice > dice && new_num >= num
				print "		目の吊り上げ\n"
				dice = new_dice
				
				flag = true
				next
			end
			
			print "		***見直してみるよ...	#{new_dice} : #{new_num}\n"
		end
		
		status = {total: total, dice: dice, num: num}
		print "		変更後：#{status}\n"
		
		return status
	end
	
	#そのターンにやるプレイヤーの処理
	def play_turn(status)
		p status
		print "#{@name}	:ブラフではない。\n"
		p "ベットを吊り上げる。"
		status = raise_a_bet(status)
		
		return status
	end
end

##########################################################################################

game = Game.new(4)

fuga = 5
fuga.times do
	game.get_scene
	game.progress_game
end
