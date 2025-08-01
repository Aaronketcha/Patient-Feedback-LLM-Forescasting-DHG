import React, { useState } from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import { MessageSquare, Clock, CheckCircle, XCircle, AlertCircle, Star } from 'lucide-react';
import BloodStockDashboard from './components/BloodStockDashboard';

// Types pour les données
interface FeedbackByRating {
  [key: string]: number;
}

interface RemindersByStatus {
  sent: number;
  failed: number;
  pending: number;
}

interface DashboardData {
  total_feedback: number;
  feedback_by_rating: FeedbackByRating;
  reminders_by_status: RemindersByStatus;
  total_reminders: number;
}

const mockData: DashboardData = {
  total_feedback: 100,
  feedback_by_rating: {
    "1": 10,
    "2": 20,
    "3": 30,
    "4": 25,
    "5": 15
  },
  reminders_by_status: {
    sent: 50,
    failed: 5,
    pending: 20
  },
  total_reminders: 75
};

// Stat card
const StatCard: React.FC<{
  title: string;
  value: number;
  icon: React.ReactNode;
  color: string;
  bgColor: string;
}> = ({ title, value, icon, color, bgColor }) => (
  <div className={`${bgColor} rounded-xl p-6 shadow-lg border border-gray-100 hover:shadow-xl transition-all duration-300`}>
    <div className="flex items-center justify-between">
      <div>
        <p className="text-gray-600 text-sm font-medium mb-1">{title}</p>
        <p className={`text-3xl font-bold ${color}`}>{value}</p>
      </div>
      <div className={`${color} p-3 rounded-lg bg-white bg-opacity-20`}>
        {icon}
      </div>
    </div>
  </div>
);

// Feedback component
const FeedbackPatientTab: React.FC<{ data: DashboardData }> = ({ data }) => {
  // Préparation des données pour les graphiques
  const ratingData = Object.entries(data.feedback_by_rating).map(([rating, count]) => ({
    rating: `${rating} étoile${rating !== '1' ? 's' : ''}`,
    count,
    fill: rating === '5' ? '#10B981' : rating === '4' ? '#34D399' : rating === '3' ? '#FCD34D' : rating === '2' ? '#F97316' : '#EF4444'
  }));

  const reminderData = [
    { name: 'Envoyés', value: data.reminders_by_status.sent, fill: '#10B981' },
    { name: 'Échoués', value: data.reminders_by_status.failed, fill: '#EF4444' },
    { name: 'En attente', value: data.reminders_by_status.pending, fill: '#F59E0B' }
  ];

  const averageRating = Object.entries(data.feedback_by_rating)
    .reduce((acc, [rating, count]) => acc + (parseInt(rating) * count), 0) / data.total_feedback;

  return (
    <div className="space-y-8">
      {/* stats card */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
          title="Total Retours"
          value={data.total_feedback}
          icon={<MessageSquare size={24} />}
          color="text-blue-600"
          bgColor="bg-gradient-to-br from-blue-50 to-blue-100"
        />
        <StatCard
          title="Note Moyenne"
          value={parseFloat(averageRating.toFixed(1))}
          icon={<Star size={24} />}
          color="text-yellow-600"
          bgColor="bg-gradient-to-br from-yellow-50 to-yellow-100"
        />
        <StatCard
          title="Total Rappels"
          value={data.total_reminders}
          icon={<Clock size={24} />}
          color="text-purple-600"
          bgColor="bg-gradient-to-br from-purple-50 to-purple-100"
        />
        <StatCard
          title="Rappels Envoyés"
          value={data.reminders_by_status.sent}
          icon={<CheckCircle size={24} />}
          color="text-green-600"
          bgColor="bg-gradient-to-br from-green-50 to-green-100"
        />
      </div>

      {/* Graphiques */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* graph note graph - remaining status chart */}
        <div className="bg-white p-6 rounded-xl shadow-lg border border-gray-100">
          <h3 className="text-xl font-semibold text-gray-800 mb-6 flex items-center">
            <Star className="mr-2 text-yellow-500" size={20} />
            Répartition des Notes
          </h3>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={ratingData} margin={{ top: 20, right: 30, left: 20, bottom: 5 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis 
                dataKey="rating" 
                tick={{ fontSize: 12 }}
                stroke="#6B7280"
              />
              <YAxis 
                tick={{ fontSize: 12 }}
                stroke="#6B7280"
              />
              <Tooltip 
                contentStyle={{
                  backgroundColor: '#f9fafb',
                  border: '1px solid #e5e7eb',
                  borderRadius: '8px'
                }}
              />
              <Bar 
                dataKey="count" 
                radius={[4, 4, 0, 0]}
                stroke="#ffffff"
                strokeWidth={2}
              />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/*remaining detail - remaining status */}
        <div className="bg-white p-6 rounded-xl shadow-lg border border-gray-100">
          <h3 className="text-xl font-semibold text-gray-800 mb-6 flex items-center">
            <Clock className="mr-2 text-purple-500" size={20} />
            Statut des Rappels
          </h3>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={reminderData}
                cx="50%"
                cy="50%"
                outerRadius={100}
                innerRadius={40}
                paddingAngle={2}
                dataKey="value"
                stroke="#ffffff"
                strokeWidth={2}
              >
                {reminderData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.fill} />
                ))}
              </Pie>
              <Tooltip 
                contentStyle={{
                  backgroundColor: '#f9fafb',
                  border: '1px solid #e5e7eb',
                  borderRadius: '8px'
                }}
              />
            </PieChart>
          </ResponsiveContainer>
          <div className="flex justify-center mt-4 space-x-6">
            {reminderData.map((item, index) => (
              <div key={index} className="flex items-center">
                <div 
                  className="w-3 h-3 rounded-full mr-2" 
                  style={{ backgroundColor: item.fill }}
                ></div>
                <span className="text-sm text-gray-600">
                  {item.name}: {item.value}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* remaining details */}
      <div className="bg-white p-6 rounded-xl shadow-lg border border-gray-100">
        <h3 className="text-xl font-semibold text-gray-800 mb-6">Détails des Rappels</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="flex items-center p-4 bg-green-50 rounded-lg border border-green-200">
            <CheckCircle className="text-green-600 mr-3" size={24} />
            <div>
              <p className="text-green-800 font-semibold">Envoyés</p>
              <p className="text-2xl font-bold text-green-600">{data.reminders_by_status.sent}</p>
              <p className="text-sm text-green-600">
                {((data.reminders_by_status.sent / data.total_reminders) * 100).toFixed(1)}%
              </p>
            </div>
          </div>
          <div className="flex items-center p-4 bg-red-50 rounded-lg border border-red-200">
            <XCircle className="text-red-600 mr-3" size={24} />
            <div>
              <p className="text-red-800 font-semibold">Échoués</p>
              <p className="text-2xl font-bold text-red-600">{data.reminders_by_status.failed}</p>
              <p className="text-sm text-red-600">
                {((data.reminders_by_status.failed / data.total_reminders) * 100).toFixed(1)}%
              </p>
            </div>
          </div>
          <div className="flex items-center p-4 bg-yellow-50 rounded-lg border border-yellow-200">
            <AlertCircle className="text-yellow-600 mr-3" size={24} />
            <div>
              <p className="text-yellow-800 font-semibold">En attente</p>
              <p className="text-2xl font-bold text-yellow-600">{data.reminders_by_status.pending}</p>
              <p className="text-sm text-yellow-600">
                {((data.reminders_by_status.pending / data.total_reminders) * 100).toFixed(1)}%
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

// nav
const PatientFeedbackDashboard: React.FC = () => {
  const [activeTab, setActiveTab] = useState('feedback-patient');

  const tabs = [
    { id: 'feedback-patient', label: 'Feedback Patient', icon: <MessageSquare size={18} /> },
    // { id: 'ai-chat', label: 'AI chat', icon: <Users size={18} /> },
    { id: 'blood-management', label: 'Blood management', icon: <Clock size={18} /> }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100">
      {/* Header */}
      <div className="bg-white shadow-sm border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="py-6">
            <h1 className="text-3xl font-bold text-gray-900">
              Système de Gestion des Retours Patients
            </h1>
            <p className="mt-2 text-gray-600">
              Tableau de bord pour le suivi et l'analyse des retours patients
            </p>
          </div>
        </div>
      </div>

      {/* tab naviguation */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="mt-8">
          <nav className="flex space-x-1 bg-white p-1 rounded-xl shadow-sm border border-gray-200">
            {tabs.map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex items-center px-6 py-3 rounded-lg font-medium text-sm transition-all duration-200 ${
                  activeTab === tab.id
                    ? 'bg-blue-600 text-white shadow-md'
                    : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
                }`}
              >
                <span className="mr-2">{tab.icon}</span>
                {tab.label}
              </button>
            ))}
          </nav>
        </div>
      </div>

      {/* tabs content*/}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {activeTab === 'feedback-patient' && <FeedbackPatientTab data={mockData} />}
        {activeTab === 'blood-management' && <BloodStockDashboard />}
      </div>
    </div>
  );
};

export default PatientFeedbackDashboard;