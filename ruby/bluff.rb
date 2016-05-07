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

#ゲームの状態を管理
GAME_START	= 0
GAME_BLUFF	= 100
GAME_CHECK	= 200


class Game
	attr_reader :status
	
	def initialize(player_num)
		@status = {total: 0, dice: 1, num: 1, game_scene: GAME_START, player_id: 0}
		
		
		#プレイヤー作る
		@players = Array.new
		player_num.times do
			@players << Player.new
			@status[:total] += DICE_MAX
		end
		
		#p "ゲーム作ったよ"
	end
	
	def get_scene
		#p @game_scene
	end
	
	#毎ターン呼んで使う
	def progress_game
		#p "*"*20, "ゲームを進めるよ"
		
		#もし、誰かがブラフと宣言していたら、ブラフ判定してそこでやめる
		if @status[:game_scene] == GAME_BLUFF then
			check_bluff
			return
		end
		
		
		#存在するプレイヤーの分だけ繰り返していく
		@players.each_with_index do |player, i|
			
			@status[:player_id] = i
			@status = player.play_turn(@status)
			
			#だれかがブラフと宣言したら、そこで抜ける
			break if @status[:game_scene] == GAME_BLUFF
		end
		
	end
	
	def subtotal_hand
		p "ダイスの集計するよ"
		
		hand_all = Array.new
		
		#存在するプレイヤーの分だけ繰り返していく
		@players.each {|player| hand_all += player.hand}
		
		return hand_all.sort
	end
	
	def check_bluff
		print "***	ブラフの判定中	***\n"
		
		hand_all = subtotal_hand
		#p hand_all, @status
		
		#ブラフか判定する
		dice	= @status[:dice]
		num		= @status[:num]
		
		target_dice = hand_all.select{|item| item == dice}.length
		
		print "宣言は、#{dice}が#{num}個\n"
		print "場には、#{dice}が#{target_dice}個\n"
		
		#宣言をしていたプレイヤーを取得しておく
		player_id = @status[:player_id]
		
		if num > target_dice then
			p "ブラフだったね"
			
			#宣言をした人がペナルティ
			if player_id == 0 then
				player_id = -1	#もし先頭のプレイヤーだったら、末端に
			else
				player_id -= 1	#そうじゃない場合は、１つ手前のプレイヤーを見る
			end
			
			p "嘘をついた、#{@players[player_id].name}さんのペナルティ"
			
		else
			p "ブラフじゃなかったね。"
			
			#ブラフって言った人がペナルティ
			p "間違ってブラフって言ってしまった、#{@players[player_id].name}さんのペナルティ"
			
		end
		
		#次のシーンへ飛ばす。このゲームは終わり
		@status[:game_scene] = GAME_CHECK
	end
	
end

class Player
	attr_reader :dice_num, :hand, :name
	
	@@player_num = 0
	
	def initialize
		@dice_num = DICE_MAX
		@hand = get_hand(@dice_num)
		
		#名前は適当。とりあえずつけておかないとテストしにくいので
		list_name = ["ramen", "curry", "yakisoba", "tenpura", "motsuni", "nikudoufu"]
		@name = list_name[@@player_num]
		
		@@player_num += 1
		
		#p "playerクラス作ったよ。今のプレイヤー数は、#{@@player_num}人だよ"
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
				status[:num] = new_num
				
				flag = true
				next
			end
			
			#同じ数だったとしても、目の数字が大きくなっていればOK
			if new_dice > dice && new_num >= num
				print "		目の吊り上げ\n"
				status[:dice] = new_dice
				
				flag = true
				next
			end
			
			print "		***見直してみるよ...	#{new_dice} : #{new_num}\n"
		end
		
		print "		変更後：#{status}\n"
		
		return status
	end
	
	#そのターンにやるプレイヤーの処理
	def play_turn(status)
		
		#ブラフか〜は今、仮にしている。
		hantei = rand(0..2)
		
		if hantei != 0 then
			print "#{@name}	:ブラフではない。\n"
			#p "ベットを吊り上げる。"
			status = raise_a_bet(status)
		else
			#もしブラフだと思ったら、シーンを切り替える
			print "#{@name}	:ブラフ！\n"
			status[:game_scene] = GAME_BLUFF
		end
		
		return status
	end
end

##########################################################################################

game = Game.new(3)

fuga = 5
fuga.times do
	game.progress_game
	
	#p game.status
	if game.status[:game_scene] == GAME_CHECK then
		p "このゲーム終了"
		break
	end
	
end
