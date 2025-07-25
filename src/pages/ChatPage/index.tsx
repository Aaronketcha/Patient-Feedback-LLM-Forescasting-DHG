import { FileText, Mic, Send, X, MicOff, Volume2 } from "lucide-react";
import { useState, useRef } from "react";

interface Message {
  id: string;
  text: string;
  isUser: boolean;
  timestamp: Date;
  type?: 'text' | 'file' | 'voice';
  fileName?: string;
  fileSize?: string;
}

const ChatPage = ({ selectedLanguage = "fr" }: { selectedLanguage?: string }) => {
  console.log(selectedLanguage)
  const [messages, setMessages] = useState<Message[]>([
    {
      id: '1',
      text: 'Bonjour ! Je suis votre assistant médical IA. Comment puis-je vous aider aujourd\'hui ? 🩺',
      isUser: false,
      timestamp: new Date(),
      type: 'text'
    }
  ]);
  const [inputText, setInputText] = useState('');
  const [isRecording, setIsRecording] = useState(false);
  const [uploadedFile, setUploadedFile] = useState<File | null>(null);
  const [isTyping, setIsTyping] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);

  const handleSendMessage = () => {
    if (!inputText.trim() && !uploadedFile) return;

    // Send text message
    if (inputText.trim()) {
      const newMessage: Message = {
        id: Date.now().toString(),
        text: inputText,
        isUser: true,
        timestamp: new Date(),
        type: 'text'
      };
      setMessages(prev => [...prev, newMessage]);
    }

    // Send file message
    if (uploadedFile) {
      const fileMessage: Message = {
        id: (Date.now() + 1).toString(),
        text: `Document médical envoyé`,
        isUser: true,
        timestamp: new Date(),
        type: 'file',
        fileName: uploadedFile.name,
        fileSize: (uploadedFile.size / 1024).toFixed(1) + ' KB'
      };
      setMessages(prev => [...prev, fileMessage]);
    }

    setInputText('');
    setUploadedFile(null);
    setIsTyping(true);

    // Simulate AI response
    setTimeout(() => {
      setIsTyping(false);
      const responses = [
        'Je comprends votre préoccupation. Pouvez-vous me donner plus de détails sur vos symptômes ? 🤔',
        'Merci pour ces informations. Depuis quand ressentez-vous ces symptômes ? 📋',
        'D\'accord, j\'ai bien reçu votre document. Laissez-moi l\'analyser pour vous aider au mieux. 📄',
        'Ces symptômes peuvent avoir plusieurs causes. Avez-vous des antécédents médicaux particuliers ? 🏥'
      ];
      
      const aiResponse: Message = {
        id: (Date.now() + 2).toString(),
        text: responses[Math.floor(Math.random() * responses.length)],
        isUser: false,
        timestamp: new Date(),
        type: 'text'
      };
      setMessages(prev => [...prev, aiResponse]);
    }, 2000);
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      // Vérifier le type de fichier (documents médicaux)
      const allowedTypes = ['application/pdf', 'image/jpeg', 'image/png', 'image/jpg', 'text/plain'];
      if (allowedTypes.includes(file.type)) {
        setUploadedFile(file);
      } else {
        alert('Type de fichier non supporté. Veuillez choisir un PDF, une image ou un fichier texte.');
      }
    }
  };

  const startRecording = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const mediaRecorder = new MediaRecorder(stream);
      mediaRecorderRef.current = mediaRecorder;
      
      const audioChunks: Blob[] = [];
      
      mediaRecorder.ondataavailable = (event) => {
        audioChunks.push(event.data);
      };
      
      mediaRecorder.onstop = () => {
        // const audioBlob = new Blob(audioChunks, { type: 'audio/wav' });
        const voiceMessage: Message = {
          id: Date.now().toString(),
          text: 'Message vocal envoyé 🎤',
          isUser: true,
          timestamp: new Date(),
          type: 'voice'
        };
        setMessages(prev => [...prev, voiceMessage]);
        
        // Simuler une réponse à l'audio
        setTimeout(() => {
          const aiResponse: Message = {
            id: (Date.now() + 1).toString(),
            text: 'J\'ai bien reçu votre message vocal. Pouvez-vous répéter ou préciser certains points ? 🔊',
            isUser: false,
            timestamp: new Date(),
            type: 'text'
          };
          setMessages(prev => [...prev, aiResponse]);
        }, 1500);
      };
      
      mediaRecorder.start();
      setIsRecording(true);
    } catch {
      alert('Impossible d\'accéder au microphone. Veuillez vérifier vos paramètres.');
    }
  };

  const stopRecording = () => {
    if (mediaRecorderRef.current && isRecording) {
      mediaRecorderRef.current.stop();
      mediaRecorderRef.current.stream.getTracks().forEach(track => track.stop());
      setIsRecording(false);
    }
  };

  const removeFile = () => {
    setUploadedFile(null);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  return (
    <div className="flex flex-col h-screen bg-gradient-to-br from-blue-50 via-white to-indigo-50">
      {/* Header */}
      {/* <div className="bg-white/80 backdrop-blur-sm border-b border-blue-100 p-4 shadow-sm">
        <div className="flex items-center space-x-3">
          <div className="w-10 h-10 bg-gradient-to-r from-blue-500 to-indigo-600 rounded-full flex items-center justify-center">
            <span className="text-white font-bold text-lg">AI</span>
          </div>
          <div>
            <h1 className="font-semibold text-gray-800">Assistant Médical IA</h1>
            <p className="text-sm text-gray-500">En ligne • Sécurisé</p>
          </div>
        </div>
      </div> */}

      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-6 space-y-6 mt-16">
        {messages.map((message) => (
          <div
            key={message.id}
            className={`flex ${message.isUser ? 'justify-end' : 'justify-start'} animate-in slide-in-from-bottom-2 duration-300`}
          >
            <div className={`flex items-end space-x-2 max-w-md ${message.isUser ? 'flex-row-reverse space-x-reverse' : ''}`}>
              {!message.isUser && (
                <div className="w-8 h-8 bg-gradient-to-r from-blue-500 to-indigo-600 rounded-full flex items-center justify-center flex-shrink-0">
                  <span className="text-white text-xs font-bold">AI</span>
                </div>
              )}
              
              <div
                className={`px-4 py-3 rounded-2xl shadow-sm ${
                  message.isUser
                    ? 'bg-gradient-to-r from-blue-500 to-indigo-600 text-white rounded-br-sm'
                    : 'bg-white text-gray-800 border border-gray-100 rounded-bl-sm'
                }`}
              >
                {message.type === 'file' && (
                  <div className="flex items-center space-x-2 mb-2">
                    <FileText className="w-4 h-4" />
                    <div className="text-xs">
                      <p className="font-medium">{message.fileName}</p>
                      <p className="opacity-70">{message.fileSize}</p>
                    </div>
                  </div>
                )}
                
                {message.type === 'voice' && (
                  <div className="flex items-center space-x-2 mb-2">
                    <Volume2 className="w-4 h-4" />
                    <div className="text-xs">
                      <p>Message vocal • 0:05</p>
                    </div>
                  </div>
                )}
                
                <p className="text-sm leading-relaxed">{message.text}</p>
                <p className={`text-xs mt-2 ${message.isUser ? 'text-blue-100' : 'text-gray-400'}`}>
                  {message.timestamp.toLocaleTimeString('fr-FR', {
                    hour: '2-digit',
                    minute: '2-digit'
                  })}
                </p>
              </div>
            </div>
          </div>
        ))}
        
        {/* Typing indicator */}
        {isTyping && (
          <div className="flex justify-start animate-pulse">
            <div className="flex items-end space-x-2">
              <div className="w-8 h-8 bg-gradient-to-r from-blue-500 to-indigo-600 rounded-full flex items-center justify-center">
                <span className="text-white text-xs font-bold">AI</span>
              </div>
              <div className="bg-white text-gray-800 border border-gray-100 rounded-2xl rounded-bl-sm px-4 py-3">
                <div className="flex space-x-1">
                  <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce"></div>
                  <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0.1s' }}></div>
                  <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0.2s' }}></div>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Input Area */}
      <div className="bg-white/80 backdrop-blur-sm border-t border-blue-100 p-4">
        {/* File preview */}
        {uploadedFile && (
          <div className="mb-3 p-3 bg-blue-50 rounded-lg border border-blue-200">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-2">
                <FileText className="w-4 h-4 text-blue-600" />
                <div className="text-sm">
                  <p className="font-medium text-blue-800">{uploadedFile.name}</p>
                  <p className="text-blue-600">{(uploadedFile.size / 1024).toFixed(1)} KB</p>
                </div>
              </div>
              <button 
                onClick={removeFile}
                className="p-1 hover:bg-blue-200 rounded-full transition-colors"
              >
                <X className="w-4 h-4 text-blue-600" />
              </button>
            </div>
          </div>
        )}

        <div className="flex items-end space-x-3">
          {/* Action buttons */}
          <div className="flex space-x-2">
            <input
              ref={fileInputRef}
              type="file"
              placeholder="_"
              onChange={handleFileUpload}
              accept=".pdf,.jpg,.jpeg,.png,.txt"
              className="hidden"
            />
            <button 
              onClick={() => fileInputRef.current?.click()}
              className="p-3 rounded-xl border border-gray-200 hover:bg-blue-50 hover:border-blue-300 transition-all duration-200 group"
              title="Ajouter un fichier"
            >
              <FileText className="w-5 h-5 text-gray-600 group-hover:text-blue-600" />
            </button>
            
            <button 
              onClick={isRecording ? stopRecording : startRecording}
              className={`p-3 rounded-xl border transition-all duration-200 ${
                isRecording 
                  ? 'bg-red-500 border-red-500 text-white animate-pulse' 
                  : 'border-gray-200 hover:bg-blue-50 hover:border-blue-300 text-gray-600 hover:text-blue-600'
              }`}
              title={isRecording ? "Arrêter l'enregistrement" : "Enregistrer un message vocal"}
            >
              {isRecording ? <MicOff className="w-5 h-5" /> : <Mic className="w-5 h-5" />}
            </button>
          </div>

          {/* Text input */}
          <div className="flex-1 relative">
            <textarea
              value={inputText}
              onChange={(e) => setInputText(e.target.value)}
              onKeyPress={handleKeyPress}
              placeholder="Décrivez vos symptômes ou posez votre question médicale..."
              className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none max-h-32 bg-white/90 backdrop-blur-sm"
              rows={1}
              style={{ minHeight: '48px' }}
            />
          </div>

          {/* Send button */}
          <button
            onClick={handleSendMessage}
            disabled={!inputText.trim() && !uploadedFile}
            className={`p-3 rounded-xl transition-all duration-200 ${
              inputText.trim() || uploadedFile
                ? 'bg-gradient-to-r from-blue-500 to-indigo-600 text-white hover:from-blue-600 hover:to-indigo-700 transform hover:scale-105 shadow-lg'
                : 'bg-gray-200 text-gray-400 cursor-not-allowed'
            }`}
          >
            <Send className="w-5 h-5" />
          </button>
        </div>

        {/* Recording indicator */}
        {isRecording && (
          <div className="mt-3 flex items-center justify-center space-x-2 text-red-500">
            <div className="w-3 h-3 bg-red-500 rounded-full animate-ping"></div>
            <span className="text-sm font-medium">Enregistrement en cours...</span>
          </div>
        )}
      </div>
    </div>
  );
};

export default ChatPage;