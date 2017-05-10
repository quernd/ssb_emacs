(require 'json)

(defun ssb-start-server () (async-shell-command "sbot server"))

(defun ssb-whoami ()
  (cdr (assoc 'id (json-read-from-string (shell-command-to-string "sbot whoami")))))

(defun ssb-id ()
  (if (ssb-whoami)
      (setq id (ssb-whoami))
    (progn (ssb-start-server) (ssb-id))))

(ssb-id)

(defun ssb-read-log (user_id)
  (shell-command-to-string 
      (concat "sbot createUserStream --id " id)))
  
(setq logs (ssb-read-log id))

(defun ssb-read-last (id) 
  (shell-command-to-string 
   (concat "sbot createUserStream --id " id " --limit 1 --reverse")))

(defun ssb-get (message_id) 
  (shell-command-to-string (concat "sbot get  " message_id)))

(defun ssb-log-type (type &optional args)
  (shell-command-to-string (concat "sbot logt --type \"" type "\"" args)))

(defun ssb-get-previous (message_id)
  ; returns previous message id given a message id
  (json-read-from-string (ssb-get (cdr (assoc 'previous message_id)))))

(defun ssb-value (message_data)
  (cdr (assoc 'value (json-read-from-string message_data))))

(defun ssb-author (message_data) 
  (cdr (assoc 'author (ssb-value message_data))))

(defun ssb-timestamp (message_data)
  (format-time-string "%D %H:%M"
                      (cdr (assoc 'timestamp 
                                  (ssb-value message_data)))))

(defun ssb-content (message_data) 
  (cdr (assoc 'content (ssb-value message_data))))

(defun ssb-text (message_data)
  (cdr (assoc 'text (ssb-content message_data))))

(defun ssb-type (message_data) 
  (cdr (assoc 'type (ssb-content message_data))))

(defun ssb-channel (message_data) 
  (cdr (assoc 'channel (ssb-content message_data))))

(defun ssb-name (message_data)
  (cdr (assoc 'name (ssb-content message_data))))

(setq names (make-hash-table))

(defun ssb-names ()
  (dolist (elt 
           (json-read-from-string (shell-command-to-string 
                                   "sbot logt --type \"about\" --reverse")))(puthash (ssb-name elt) (ssb-author elt) names)))

(ssb-names)
(maphash 'print names)

(defun ssb-decode (message_id) 
  (shell-command-to-string (concat "sbot private.unbox " message_id)))

(defun ssb-display (message_data)
  (with-output-to-temp-buffer "Message"
    (let (type)
      (setq type (ssb-type message_data)))
    (print (concat "Type: " type))
    (print (concat "Time: " (ssb-timestamp message_data)))
    (print (concat "Channel: " (ssb-channel message_data)))
    (print (ssb-text message_data))
    (print message_data)))

(defun ssb-display-buffer (message_data)
  (get-buffer-create "SSB-Message")
  (set-buffer "SSB-Message")
  (princ (gethash (ssb-author message_data) names)) 
  (princ (ssb-timestamp message_data))
  (let (type)
    (setq type (ssb-type message_data))
    (cond ((eq type "post")
           (print (ssb-text message_data)))
          ((eq type "channel")
           (princ (concat "subscribed to" (ssb-channel message_data)))
           (t (print type))))))

;(ssb-display (ssb-read-last id))
(ssb-display-buffer (ssb-read-last id))

(ssb-read-last id)
(defun ssb-publish (text) 
  ; publish a message
  (shell-command-to-string 
   (concat "sbot publish --type post --text \"" text "\"")))

(defun ssb-quick-message (message)
  ; Create a quick message from the minibuffer.  No use of RET, /n only.
  (interactive "sMessage: " )
  (ssb-publish message))

(gethash "@+D0ku/LReK6kqd3PSrcVCfbLYbDtTmS4Bd21rqhpYNA=.ed25519" names)
(defun ssb-live-feed (id)
  (async-shell-command "sbot feed --live --reverse --limit 5"))


;set keymaps
(global-set-key "\C-s s" 'ssb-start-server)
(global-set-key "\C-s p" 'ssb-publish)
(global-set-key "\C-s c" 'ssb-quick-message)
(global-set-key "\C-s w" 'ssb-whoami)

 
