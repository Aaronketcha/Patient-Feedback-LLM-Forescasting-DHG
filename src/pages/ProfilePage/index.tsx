import React, { useState } from 'react';
import {
  Search,
  Loader2,
  User
} from 'lucide-react';

interface Patient {
  id: string;
  name: string;
  age: number;
  gender: string;
  consultations: Consultation[];
}

interface Consultation {
  id: string;
  date: Date;
  diagnosis: string;
  temperature: number;
  bloodPressure: string;
  pulse: number;
  summary: string;
}

const mockPatients: Patient[] = [
  {
    id: "P001",
    name: "Marie Dubois",
    age: 34,
    gender: "Féminin",
    consultations: [
      {
        id: "C001",
        date: new Date("2024-07-20"),
        diagnosis: "Grippe saisonnière",
        temperature: 38.5,
        bloodPressure: "120/80",
        pulse: 85,
        summary: "Symptômes grippaux avec fièvre modérée. Traitement symptomatique recommandé avec paracétamol et repos."
      },
      {
        id: "C002",
        date: new Date("2024-06-15"),
        diagnosis: "Contrôle de routine",
        temperature: 36.8,
        bloodPressure: "115/75",
        pulse: 72,
        summary: "Examen de routine annuel. Tous les paramètres vitaux dans la normale. Vaccination à jour."
      },
      {
        id: "C003",
        date: new Date("2024-05-10"),
        diagnosis: "Bronchite aiguë",
        temperature: 37.8,
        bloodPressure: "118/78",
        pulse: 82,
        summary: "Toux persistante avec expectoration. Prescription d'antibiotiques et antitussifs."
      }
    ]
  },
  {
    id: "P002",
    name: "Jean Martin",
    age: 45,
    gender: "Masculin",
    consultations: [
      {
        id: "C004",
        date: new Date("2024-07-22"),
        diagnosis: "Hypertension artérielle",
        temperature: 37.0,
        bloodPressure: "145/95",
        pulse: 88,
        summary: "Tension artérielle élevée. Ajustement du traitement antihypertenseur. Suivi dans 1 mois."
      },
      {
        id: "C005",
        date: new Date("2024-06-20"),
        diagnosis: "Diabète type 2 - suivi",
        temperature: 36.9,
        bloodPressure: "140/90",
        pulse: 80,
        summary: "Contrôle glycémique satisfaisant. HbA1c à 7.2%. Poursuite du traitement actuel."
      }
    ]
  },
  {
    id: "P003",
    name: "Sophie Lemaire",
    age: 28,
    gender: "Féminin",
    consultations: [
      {
        id: "C006",
        date: new Date("2024-07-18"),
        diagnosis: "Migraine",
        temperature: 36.7,
        bloodPressure: "110/70",
        pulse: 68,
        summary: "Céphalée intense avec photophobie. Prescription de triptans. Conseils d'hygiène de vie."
      }
    ]
  }
];

const Profile: React.FC = () => {
  const [patientId, setPatientId] = useState('');
  const [loading, setLoading] = useState(false);
  const [selectedPatient, setSelectedPatient] = useState<Patient | null>(null);
  const [selectedConsultation, setSelectedConsultation] = useState<Consultation | null>(null);
  const [searchAttempted, setSearchAttempted] = useState(false);

  const handleSearch = async () => {
    if (!patientId.trim()) return;

    setLoading(true);
    setSearchAttempted(true);
    setSelectedConsultation(null);

    // Simulate API call
    setTimeout(() => {
      const patient = mockPatients.find(p => p.id.toLowerCase() === patientId.toLowerCase());
      setSelectedPatient(patient || null);
      setLoading(false);
    }, 1500);
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleSearch();
    }
  };

  return (
    <div className="min-h-screen bg-gray-50" style={{ paddingTop: '64px' }}>

      <div className="max-w-4xl mx-auto px-4 py-6">
        <h1 className="text-2xl font-bold text-gray-800 mb-6">Profil Patient</h1>

        {/* Search Section */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
          <h2 className="text-lg font-semibold text-gray-800 mb-4">Recherche Patient</h2>

          <div className="flex space-x-4">
            <div className="flex-1">
              <input
                type="text"
                value={patientId}
                onChange={(e) => setPatientId(e.target.value)}
                onKeyPress={handleKeyPress}
                placeholder="Entrez l'ID du patient (ex: P001, P002, P003)"
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent"
              />
              <p className="text-sm text-gray-500 mt-2">
                IDs disponibles pour test: P001, P002, P003
              </p>
            </div>
            <button
              onClick={handleSearch}
              disabled={loading || !patientId.trim()}
              className="px-6 py-2 bg-primary text-white rounded-lg hover:bg-blue-600 disabled:opacity-50 disabled:cursor-not-allowed flex items-center space-x-2"
            >
              {loading ? (
                <Loader2 className="w-5 h-5 animate-spin" />
              ) : (
                <Search className="w-5 h-5" />
              )}
              <span>Rechercher</span>
            </button>
          </div>
        </div>

        {/* Patient Information */}
        {selectedPatient && (
          <div className="space-y-6">
            <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
              <h2 className="text-lg font-semibold text-gray-800 mb-4">Informations Patient</h2>
              <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                <div>
                  <p className="text-sm text-gray-600">Nom</p>
                  <p className="font-medium text-gray-800">{selectedPatient.name}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-600">ID</p>
                  <p className="font-medium text-gray-800">{selectedPatient.id}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-600">Âge</p>
                  <p className="font-medium text-gray-800">{selectedPatient.age} ans</p>
                </div>
                <div>
                  <p className="text-sm text-gray-600">Genre</p>
                  <p className="font-medium text-gray-800">{selectedPatient.gender}</p>
                </div>
              </div>
            </div>

            {/* Consultations */}
            <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
              <h2 className="text-lg font-semibold text-gray-800 mb-4">
                Consultations ({selectedPatient.consultations.length})
              </h2>
              <div className="space-y-3">
                {selectedPatient.consultations
                  .sort((a, b) => b.date.getTime() - a.date.getTime())
                  .map((consultation) => (
                    <div key={consultation.id} className="border border-gray-200 rounded-lg p-4">
                      <button
                        onClick={() => setSelectedConsultation(
                          selectedConsultation?.id === consultation.id ? null : consultation
                        )}
                        className="w-full text-left"
                      >
                        <div className="flex justify-between items-center">
                          <div>
                            <span className="font-medium text-gray-800">
                              {consultation.date.toLocaleDateString('fr-FR', {
                                year: 'numeric',
                                month: 'long',
                                day: 'numeric'
                              })}
                            </span>
                            <span className="text-sm text-gray-500 ml-2">
                              {consultation.date.toLocaleTimeString('fr-FR', {
                                hour: '2-digit',
                                minute: '2-digit'
                              })}
                            </span>
                          </div>
                          <span className="text-sm text-primary font-medium">{consultation.diagnosis}</span>
                        </div>
                      </button>

                      {selectedConsultation?.id === consultation.id && (
                        <div className="mt-4 pt-4 border-t border-gray-200">
                          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
                            <div className="bg-gray-50 p-3 rounded-lg">
                              <p className="text-sm text-gray-600 font-medium">Température</p>
                              <p className="text-lg font-semibold text-gray-800">{consultation.temperature}°C</p>
                            </div>
                            <div className="bg-gray-50 p-3 rounded-lg">
                              <p className="text-sm text-gray-600 font-medium">Tension</p>
                              <p className="text-lg font-semibold text-gray-800">{consultation.bloodPressure}</p>
                            </div>
                            <div className="bg-gray-50 p-3 rounded-lg">
                              <p className="text-sm text-gray-600 font-medium">Pouls</p>
                              <p className="text-lg font-semibold text-gray-800">{consultation.pulse} bpm</p>
                            </div>
                            <div className="bg-gray-50 p-3 rounded-lg">
                              <p className="text-sm text-gray-600 font-medium">Diagnostic</p>
                              <p className="text-sm font-medium text-primary">{consultation.diagnosis}</p>
                            </div>
                          </div>
                          <div className="bg-blue-50 p-4 rounded-lg">
                            <p className="text-sm text-gray-600 font-medium mb-2">Résumé de la consultation</p>
                            <p className="text-gray-800 leading-relaxed">{consultation.summary}</p>
                          </div>
                        </div>
                      )}
                    </div>
                  ))}
              </div>
            </div>
          </div>
        )}

        {/* No Patient Found */}
        {searchAttempted && !selectedPatient && !loading && patientId && (
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <div className="text-center py-8">
              <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <User className="w-8 h-8 text-gray-400" />
              </div>
              <h3 className="text-lg font-medium text-gray-800 mb-2">Patient non trouvé</h3>
              <p className="text-gray-600">Aucun patient trouvé avec l'ID: <strong>{patientId}</strong></p>
              <p className="text-sm text-gray-500 mt-2">
                Vérifiez l'ID ou essayez: P001, P002, ou P003
              </p>
            </div>
          </div>
        )}

        {/* Initial State */}
        {!searchAttempted && !selectedPatient && (
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <div className="text-center py-12">
              <div className="w-16 h-16 bg-primary rounded-full flex items-center justify-center mx-auto mb-4">
                <Search className="w-8 h-8 text-white" />
              </div>
              <h3 className="text-lg font-medium text-gray-800 mb-2">Recherche de patient</h3>
              <p className="text-gray-600">Entrez un ID patient pour consulter son dossier médical</p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Profile;