import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { User } from 'lucide-react';

const Login = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const navigate = useNavigate();

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    // Simulate login - store user data in localStorage
    const userData = {
      id: '1',
      name: 'Dr. Smith',
      email: 'dr.smith@example.com',
      username: username,
      isFirstLogin: true
    };
    
    localStorage.setItem('user', JSON.stringify(userData));
    navigate('/');
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary to-secondary flex items-center justify-center">

      <div className="bg-white rounded-2xl p-8 shadow-2xl max-w-md w-full mx-4">
        <div className="text-center mb-8">
          <div className="w-16 h-16 bg-primary rounded-full flex items-center justify-center mx-auto mb-4">
            <User className="w-8 h-8 text-white" />
          </div>
          <h2 className="text-2xl font-bold text-gray-800">Connexion</h2>
          <p className="text-gray-600">Accédez à votre assistant médical</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Identifiant
            </label>
            <input
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-primary focus:border-transparent"
              placeholder="Votre identifiant"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Mot de passe
            </label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-primary focus:border-transparent"
              placeholder="Votre mot de passe"
              required
            />
          </div>

          <button
            type="submit"
            className="w-full bg-primary text-white py-3 rounded-xl font-medium hover:bg-blue-600 transition-colors"
          >
            Connexion
          </button>
        </form>

        <p className="text-center mt-6 text-gray-600">
          Pas de compte ?{' '}
          <Link
            to="/register"
            className="text-primary font-medium hover:underline"
          >
            Inscrivez-vous
          </Link>
        </p>
      </div>
    </div>
  );
};

export default Login;