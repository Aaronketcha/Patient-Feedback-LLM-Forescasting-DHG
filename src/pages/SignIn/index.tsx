import { User } from "lucide-react";
import { useState } from "react";
import { NavLink } from "react-router-dom";

const SignIn = () => {
  const [name, setName] = useState('');
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // onRegister(name, username, email, password);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary to-secondary flex items-center justify-center">
      <div className="bg-white rounded-2xl p-8 shadow-2xl max-w-md w-full mx-4">
        <div className="text-center mb-8">
          <div className="w-16 h-16 bg-secondary rounded-full flex items-center justify-center mx-auto mb-4">
            <User className="w-8 h-8 text-white" />
          </div>
          <h2 className="text-2xl font-bold text-gray-800">Inscription</h2>
          <p className="text-gray-600">Créez votre compte</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Nom complet
            </label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-primary focus:border-transparent"
              placeholder="Votre nom complet"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Identifiant
            </label>
            <input
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-primary focus:border-transparent"
              placeholder="Choisissez un identifiant"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Email
            </label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-primary focus:border-transparent"
              placeholder="votre@email.com"
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
              placeholder="Créez un mot de passe"
              required
            />
          </div>

          <button
            type="submit"
            className="w-full bg-secondary text-white py-3 rounded-xl font-medium hover:bg-purple-600 transition-colors"
          >
            S'inscrire
          </button>
        </form>

        <p className="text-center mt-6 text-gray-600">
          Déjà un compte ?{' '}
          <NavLink
            to={"/login"}
            className="text-primary font-medium hover:underline"
          >
            Connectez-vous
          </NavLink>
        </p>
      </div>
    </div>
  );
};

export default SignIn;