import { useState } from 'react';
import {
  UserCircle,
} from 'lucide-react';
import { NavLink } from 'react-router-dom';

const Header = () => {
  const [showUserMenu, setShowUserMenu] = useState(false);


  return (
    <>
      <header className="bg-white absolute w-full shadow-sm border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center space-x-4">
              <img className='w-16 h-16' src="/logo.svg" alt="logo" />
              <h1 className="text-xl font-semibold text-primary">Assistant Médical</h1>
            </div>

            <div className="relative">
              <button
                onClick={() => setShowUserMenu(!showUserMenu)}
                className="flex items-center space-x-2 p-2 rounded-lg hover:bg-gray-100"
              >
                <UserCircle className="w-8 h-8 text-primary" />
                {/* <span className="text-sm font-medium text-gray-700">user.name</span> */}
              </button>

              {showUserMenu && (
                <div className="absolute right-0 mt-2 w-48 bg-white rounded-lg shadow-lg border border-gray-200 z-50">
                  <div className="py-1 flex flex-col">
                    <NavLink
                      to={"/"}
                      onClick={() => {
                        setShowUserMenu(false);
                      }}
                      className="w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                    >
                      Discussion avec l'agent
                    </NavLink>
                    <NavLink
                      to={"/profile"}
                      onClick={() => {
                        setShowUserMenu(false);
                      }}
                      className="w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                    >
                      Mon Profil
                    </NavLink>
                    <NavLink
                      to={"/history"}
                      onClick={() => {
                        setShowUserMenu(false);
                      }}
                      className="w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                    >
                      Historique
                    </NavLink>
                    <button
                      onClick={() => {
                        setShowUserMenu(false);
                      }}
                      className="w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                    >
                      Déconnexion
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </header>

    </>
  );
};

export default Header;