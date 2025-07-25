import { History, MessageCircle, X } from "lucide-react";

const Sidebar = ({ isOpen, onClose, onNavigate }: {
  isOpen: boolean;
  onClose: () => void;
  onNavigate: (page: string) => void;
}) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50">
      <div className="fixed inset-0 bg-black bg-opacity-50" onClick={onClose} />
      <div className="fixed left-0 top-0 h-full w-80 bg-white shadow-xl">
        <div className="flex items-center justify-between p-4 border-b border-gray-200">
          <h2 className="text-lg font-semibold text-gray-800">Menu</h2>
          <button onClick={onClose} className="p-2 rounded-lg hover:bg-gray-100">
            <X className="w-5 h-5 text-gray-600" />
          </button>
        </div>

        <nav className="p-4 space-y-2">
          <button
            onClick={() => {
              onNavigate('chat');
              onClose();
            }}
            className="w-full flex items-center space-x-3 p-3 rounded-lg hover:bg-gray-100 text-left"
          >
            <MessageCircle className="w-5 h-5 text-primary" />
            <span className="text-gray-700">Parler avec l'agent</span>
          </button>

          <button
            onClick={() => {
              onNavigate('history');
              onClose();
            }}
            className="w-full flex items-center space-x-3 p-3 rounded-lg hover:bg-gray-100 text-left"
          >
            <History className="w-5 h-5 text-primary" />
            <span className="text-gray-700">Historique des discussions</span>
          </button>
        </nav>
      </div>
    </div>
  );
};

export default Sidebar;