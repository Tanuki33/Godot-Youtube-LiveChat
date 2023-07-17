extends Node

@export var ChatUrl = ""
@onready var normalChatBubble = preload("res://res/Components/normalChatBubble.tscn")

var INNERTUBE_API_KEY = ""
var HaveKey = false
var HeaderPost = [
	"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36",
	"Content-Type: application/json"
	]
var lastContinuation = ""

func _ready():
	DisplayServer.window_set_title("Waiting Response...")
	$HTTPRequest.request(ChatUrl, ["User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36"])

func renderChat(liveData):
	var data = await JSON.parse_string(liveData)
	if data == null:
		getChat(lastContinuation)
		return
	if data.has("error"):
		getChat(lastContinuation)
		return
	var continuation = await str(data.continuationContents.liveChatContinuation.continuations[0].invalidationContinuationData.continuation) if data.continuationContents.liveChatContinuation.continuations[0].has("invalidationContinuationData") else data.continuationContents.liveChatContinuation.continuations[0].timedContinuationData.continuation
	lastContinuation = continuation
	var liveChat = data.continuationContents.liveChatContinuation
	if liveChat.has("actions"):
		var ChatData = await data.continuationContents.liveChatContinuation.actions
		for chatData in ChatData:
			var itemData = ""
			if chatData.has("removeChatItemAction"):
				print("delete chat")
				getChat(continuation)
			if chatData.has("addLiveChatTickerItemAction"):
				itemData = chatData.addLiveChatTickerItemAction.item.liveChatTickerPaidMessageItemRenderer
				superChat(itemData, continuation)
			if chatData.has("addChatItemAction"):
				itemData = chatData.addChatItemAction.item
				normalChat(itemData, continuation)
			if chatData.has("updateLiveChatPollAction"):
				chatPoll(itemData, continuation)
	else:
		getChat(continuation)

func normalChat(itemData, continuation):
	var senderName = ""
	var senderMessage = ""
	var message = ""
	var badges = ""

	if itemData.has("liveChatMembershipItemRenderer"):
		badges = itemData.liveChatMembershipItemRenderer.authorBadges[0].liveChatAuthorBadgeRenderer.tooltip
		senderName = itemData.liveChatMembershipItemRenderer.authorName.simpleText + " [color=blue]" + badges +"[/color]"
		print(itemData.liveChatMembershipItemRenderer)
		#senderMessage = itemData.liveChatMembershipItemRenderer.authorName.simpleText
	elif itemData.has("liveChatTextMessageRenderer"):
		badges = (itemData.liveChatTextMessageRenderer.authorBadges[0].liveChatAuthorBadgeRenderer.tooltip if itemData.liveChatTextMessageRenderer.has("authorBadges") else "")
		senderName = (itemData.liveChatTextMessageRenderer.authorName.simpleText if (itemData.liveChatTextMessageRenderer.has("authorName")) else " ") + " [color=blue]" + badges +"[/color]"
		senderMessage = itemData.liveChatTextMessageRenderer.message.runs
	
	for chat in senderMessage:
		if chat.has("text"):
			message += str(chat.text) + " "
		elif chat.has("emoji"):
			if chat.emoji.has("isCustomEmoji"):
				var url = chat.emoji.image.thumbnails[1].url
				var emojiShortcut = (chat.emoji.shortcuts[1] if (chat.emoji.shortcuts.size() > 1) else chat.emoji.shortcuts[0])
				message += "[color=black]" + str(emojiShortcut) + "[/color] "
				await customEmojiHandler(url,emojiShortcut)
			else:
				message += str(chat.emoji.emojiId) + " "
	var ChatObj = normalChatBubble.instantiate()
	ChatObj.get_node("Name").text = str(senderName)
	ChatObj.get_node("Chat").text = str(message)
	$Control/LiveChats.add_child(ChatObj)
	getChat(continuation)

func superChat(itemData, continuation):
	var paidChatData = itemData.showItemEndpoint.showLiveChatItemEndpoint.renderer.liveChatPaidMessageRenderer
	var badges = itemData.authorBadges[0].liveChatAuthorBadgeRenderer.tooltip if itemData.has("authorBadges") else ""
	var senderName = paidChatData.authorName.simpleText + " [color=red]" + badges + "[/color]"
	var senderMessage = paidChatData.message.runs
	var message = ""
	var duration = itemData.fullDurationSec
	var photo = itemData.authorPhoto.thumbnails[1].url
	var amount = str(itemData.amount.simpleText)
			
	for chat in senderMessage:
		if chat.has("text"):
			message += str(chat.text)
		elif chat.has("emoji"):
			if chat.emoji.has("isCustomEmoji"):
				var url = chat.emoji.image.thumbnails[1].url
				var emojiShortcut = (chat.emoji.shortcuts[1] if (chat.emoji.shortcuts.size() > 1) else chat.emoji.shortcuts[0])
				message += "[color=black]" + str(emojiShortcut) + "[/color] "
				await customEmojiHandler(url,emojiShortcut)
			else:
				message += str(chat.emoji.emojiId)
	var ChatObj = normalChatBubble.instantiate()
	ChatObj.get_node("Name").text = str(senderName)
	ChatObj.get_node("Chat").text = str(message)
	$Control/LiveChats.add_child(ChatObj)
	getChat(continuation)
	
func getChat(continuation):
	var Query = {
		  "context": {
			"client": {
			  "userAgent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36,gzip(gfe)",
			  "clientName": "WEB",
			  "clientVersion": "2.20230714.00.00",
			  "osName": "Windows",
			  "osVersion": "10.0",
			  "originalUrl": ChatUrl,
			  "platform": "DESKTOP",
			  "clientFormFactor": "UNKNOWN_FORM_FACTOR",
			  "mainAppWebInfo": {
				"graftUrl": ChatUrl,
				"webDisplayMode": "WEB_DISPLAY_MODE_BROWSER",
				"isWebNativeShareAvailable": true
			  },
			  "timeZone": "Asia/Jakarta"
			}
		  },
		  "continuation": continuation,
		  "webClientInfo": {
			"isDocumentHidden": true
		  }
		}
	$HTTPRequest.request("https://www.youtube.com/youtubei/v1/live_chat/get_live_chat?key="+ INNERTUBE_API_KEY , HeaderPost, HTTPClient.METHOD_POST, JSON.stringify(Query))

func getMetadata(continuation):
	var Query = {
		  "context": {
			"client": {
			  "userAgent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36,gzip(gfe)",
			  "clientName": "WEB",
			  "clientVersion": "2.20230714.00.00",
			  "osName": "Windows",
			  "osVersion": "10.0",
			  "originalUrl": ChatUrl,
			  "platform": "DESKTOP",
			  "clientFormFactor": "UNKNOWN_FORM_FACTOR",
			  "mainAppWebInfo": {
				"graftUrl": ChatUrl,
				"webDisplayMode": "WEB_DISPLAY_MODE_BROWSER",
				"isWebNativeShareAvailable": true
			  },
			  "timeZone": "Asia/Jakarta"
			}
		  },
		  "continuation": continuation,
		  "webClientInfo": {
			"isDocumentHidden": true
		  }
		}
	$HTTPRequest.request("https://www.youtube.com/youtubei/v1/updated_metadata?key="+ INNERTUBE_API_KEY , HeaderPost, HTTPClient.METHOD_POST, JSON.stringify(Query))

func customEmojiHandler(url, emojiShortcut):
	pass

func chatPoll(itemData, continuation):
	getChat(continuation)

func _on_http_request_request_completed(result, response_code, headers, body):
	body = await body.get_string_from_utf8()
	if HaveKey == false:
		var RegEx_Innertube = RegEx.new()
		RegEx_Innertube.compile("INNERTUBE_API_KEY..\"(.*?)\"")
		INNERTUBE_API_KEY = RegEx_Innertube.search(body).get_string(1)
		var RegEx_Continuation = RegEx.new()
		RegEx_Continuation.compile("continuation..\"(.*?)\"")
		var continuation = RegEx_Continuation.search(body)
		if continuation == null:
			$Control/Metadata/viewCount.text = "Stream Ended."
			return
		if INNERTUBE_API_KEY:
			HaveKey = true
			lastContinuation = continuation
			DisplayServer.window_set_title("Tan - Youtube Live Chat")
			await getChat(continuation.get_string(1))
	elif INNERTUBE_API_KEY and HaveKey:
		await renderChat(str(JSON.parse_string(body)))

var conversion_table = {0: '0', 1: '1', 2: '2', 3: '3', 4: '4',
					5: '5', 6: '6', 7: '7',
					8: '8', 9: '9', 10: 'A', 11: 'B', 12: 'C',
					13: 'D', 14: 'E', 15: 'F'}
 
func decimalToHexadecimal(decimal):
	var hexadecimal = ''
	while(decimal > 0):
		var remainder = decimal % 16
		hexadecimal = conversion_table[remainder] + hexadecimal
		decimal = floor(decimal / 16)

	return hexadecimal
