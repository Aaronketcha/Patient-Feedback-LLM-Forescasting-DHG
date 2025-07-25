import React, { useState } from 'react';
import {
    MoreHorizontal,
    Edit3,
    Trash2
} from 'lucide-react';

interface Message {
    id: string;
    text: string;
    isUser: boolean;
    timestamp: Date;
}

interface Conversation {
    id: string;
    title: string;
    messages: Message[];
    lastMessage: Date;
}

const mockConversations: Conversation[] = [
    {
        id: "conv1",
        title: "Symptômes grippaux",
        lastMessage: new Date(),
        messages: [
            { id: "1", text: "Bonjour, j'ai des symptômes de grippe", isUser: true, timestamp: new Date() },
            { id: "2", text: "Bonjour ! Pouvez-vous me décrire vos symptômes en détail ?", isUser: false, timestamp: new Date() }
        ]
    },
    {
        id: "conv2",
        title: "Question sur médicaments",
        lastMessage: new Date(Date.now() - 86400000),
        messages: [
            { id: "3", text: "Puis-je prendre de l'ibuprofène avec mes médicaments ?", isUser: true, timestamp: new Date() },
            { id: "4", text: "Pour votre sécurité, je recommande de consulter votre médecin...", isUser: false, timestamp: new Date() }
        ]
    },
    {
        id: "conv3",
        title: "Douleurs abdominales",
        lastMessage: new Date(Date.now() - 2 * 86400000),
        messages: [
            { id: "5", text: "J'ai des douleurs au ventre depuis hier", isUser: true, timestamp: new Date() },
            { id: "6", text: "Je comprends votre inquiétude. Pouvez-vous localiser précisément la douleur ?", isUser: false, timestamp: new Date() }
        ]
    },
    {
        id: "conv4",
        title: "Suivi de tension",
        lastMessage: new Date(Date.now() - 7 * 86400000),
        messages: [
            { id: "7", text: "Ma tension était de 14/9 ce matin", isUser: true, timestamp: new Date() },
            { id: "8", text: "Cette valeur est légèrement élevée. Avez-vous pris vos médicaments ?", isUser: false, timestamp: new Date() }
        ]
    }
];

const History: React.FC = () => {
    const [conversations] = useState(mockConversations);
    const [selectedConversation, setSelectedConversation] = useState<string | null>(null);

    const groupConversationsByDate = () => {
        const today = new Date();
        const yesterday = new Date(today);
        yesterday.setDate(yesterday.getDate() - 1);

        const groups: { [key: string]: Conversation[] } = {
            'Aujourd\'hui': [],
            'Hier': [],
            'Plus ancien': []
        };

        conversations.forEach(conv => {
            const convDate = new Date(conv.lastMessage);
            if (convDate.toDateString() === today.toDateString()) {
                groups['Aujourd\'hui'].push(conv);
            } else if (convDate.toDateString() === yesterday.toDateString()) {
                groups['Hier'].push(conv);
            } else {
                groups['Plus ancien'].push(conv);
            }
        });

        return groups;
    };

    const groupedConversations = groupConversationsByDate();

    const handleMenuAction = (action: string, conversationId: string) => {
        if (action === 'rename') {
            const newTitle = prompt('Nouveau titre pour cette conversation:');
            if (newTitle) {
                // In a real app, this would update the conversation in the backend
                console.log(`Renaming conversation ${conversationId} to: ${newTitle}`);
            }
        } else if (action === 'delete') {
            if (confirm('Êtes-vous sûr de vouloir supprimer cette conversation ?')) {
                // In a real app, this would delete the conversation from the backend
                console.log(`Deleting conversation ${conversationId}`);
            }
        }
        setSelectedConversation(null);
    };

    return (
        <div className="min-h-screen bg-gray-50" style={{ paddingTop: '64px' }}>

            <div className="max-w-4xl mx-auto px-4 py-6">
                <h1 className="text-2xl font-bold text-gray-800 mb-6">Historique des discussions</h1>

                {Object.entries(groupedConversations).map(([period, convs]) => {
                    if (convs.length === 0) return null;

                    return (
                        <div key={period} className="mb-8">
                            <h2 className="text-lg font-semibold text-gray-700 mb-4">{period}</h2>
                            <div className="space-y-3">
                                {convs.map((conversation) => (
                                    <div
                                        key={conversation.id}
                                        className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 hover:shadow-md transition-shadow"
                                    >
                                        <div className="flex items-center justify-between">
                                            <div className="flex-1">
                                                <h3 className="font-medium text-gray-800">{conversation.title}</h3>
                                                <p className="text-sm text-gray-500 mt-1">
                                                    {conversation.lastMessage.toLocaleDateString('fr-FR')} à{' '}
                                                    {conversation.lastMessage.toLocaleTimeString('fr-FR', {
                                                        hour: '2-digit',
                                                        minute: '2-digit'
                                                    })}
                                                </p>
                                                <p className="text-sm text-gray-600 mt-2 truncate">
                                                    {conversation.messages[conversation.messages.length - 1]?.text}
                                                </p>
                                            </div>

                                            <div className="relative">
                                                <button
                                                    onClick={() => setSelectedConversation(
                                                        selectedConversation === conversation.id ? null : conversation.id
                                                    )}
                                                    className="p-2 rounded-lg hover:bg-gray-100"
                                                >
                                                    <MoreHorizontal className="w-5 h-5 text-gray-600" />
                                                </button>

                                                {selectedConversation === conversation.id && (
                                                    <div className="absolute right-0 mt-2 w-48 bg-white rounded-lg shadow-lg border border-gray-200 z-10">
                                                        <div className="py-1">
                                                            <button
                                                                onClick={() => handleMenuAction('rename', conversation.id)}
                                                                className="w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 flex items-center space-x-2"
                                                            >
                                                                <Edit3 className="w-4 h-4" />
                                                                <span>Renommer</span>
                                                            </button>
                                                            <button
                                                                onClick={() => handleMenuAction('delete', conversation.id)}
                                                                className="w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-red-50 flex items-center space-x-2"
                                                            >
                                                                <Trash2 className="w-4 h-4" />
                                                                <span>Supprimer</span>
                                                            </button>
                                                        </div>
                                                    </div>
                                                )}
                                            </div>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </div>
                    );
                })}

                {conversations.length === 0 && (
                    <div className="text-center py-12">
                        <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                            <MoreHorizontal className="w-8 h-8 text-gray-400" />
                        </div>
                        <h3 className="text-lg font-medium text-gray-800 mb-2">Aucune conversation</h3>
                        <p className="text-gray-600">Commencez une nouvelle conversation avec votre assistant médical</p>
                    </div>
                )}
            </div>
        </div>
    );
};

export default History;