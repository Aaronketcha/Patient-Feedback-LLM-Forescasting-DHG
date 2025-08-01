import React, { useState, useEffect } from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import { DatePicker, Select, Table, Button } from 'antd';
import { DownloadOutlined, FilterOutlined } from '@ant-design/icons';
import dayjs from 'dayjs';

const { Option } = Select;
const { RangePicker } = DatePicker;

// Données mockées
const mockBloodStock = [
  { id: 1, bloodType: 'A+', quantity: 42, status: 'disponible', location: 'Banque centrale', expiryDate: '2023-12-15' },
  { id: 2, bloodType: 'O-', quantity: 35, status: 'réservé', location: 'Hôpital Principal', expiryDate: '2023-11-28' },
  { id: 3, bloodType: 'B+', quantity: 28, status: 'proche péremption', location: 'Clinique Nord', expiryDate: '2023-11-05' },
  { id: 4, bloodType: 'AB-', quantity: 15, status: 'expiré', location: 'Banque centrale', expiryDate: '2023-10-20' },
  { id: 5, bloodType: 'A-', quantity: 31, status: 'disponible', location: 'Hôpital Principal', expiryDate: '2023-12-20' },
  { id: 6, bloodType: 'O+', quantity: 50, status: 'disponible', location: 'Clinique Nord', expiryDate: '2023-12-10' },
];

const BloodStockDashboard = () => {
  const [data, setData] = useState(mockBloodStock);
  const [filteredData, setFilteredData] = useState(mockBloodStock);
  const [filters, setFilters] = useState({
    bloodType: null,
    location: null,
    dateRange: null,
  });

  // Appliquer les filtres
  useEffect(() => {
    let result = [...data];

    if (filters.bloodType) {
      result = result.filter(item => item.bloodType === filters.bloodType);
    }

    if (filters.location) {
      result = result.filter(item => item.location === filters.location);
    }

    if (filters.dateRange) {
      const [start, end] = filters.dateRange;
      result = result.filter(item => {
        const expiryDate = dayjs(item.expiryDate);
        return expiryDate.isAfter(start) && expiryDate.isBefore(end);
      });
    }

    setFilteredData(result);
  }, [filters, data]);

  // Préparer les données pour les graphiques
  const bloodTypeDistribution = filteredData.reduce((acc, item) => {
    const existing = acc.find(i => i.name === item.bloodType);
    if (existing) {
      existing.value += item.quantity;
    } else {
      acc.push({ name: item.bloodType, value: item.quantity });
    }
    return acc;
  }, []);

  const statusDistribution = filteredData.reduce((acc, item) => {
    const existing = acc.find(i => i.name === item.status);
    if (existing) {
      existing.value += item.quantity;
    } else {
      acc.push({ name: item.status, value: item.quantity });
    }
    return acc;
  }, []);

  // Couleurs pour les statuts
  const statusColors = {
    'disponible': '#4CAF50',
    'réservé': '#2196F3',
    'proche péremption': '#FFC107',
    'expiré': '#F44336'
  };

  // Colonnes pour le tableau
  const columns = [
    {
      title: 'Groupe Sanguin',
      dataIndex: 'bloodType',
      key: 'bloodType',
      sorter: (a, b) => a.bloodType.localeCompare(b.bloodType),
    },
    {
      title: 'Quantité (pochettes)',
      dataIndex: 'quantity',
      key: 'quantity',
      sorter: (a, b) => a.quantity - b.quantity,
    },
    {
      title: 'Statut',
      dataIndex: 'status',
      key: 'status',
      render: (status) => (
        <span style={{
          padding: '4px 8px',
          borderRadius: '4px',
          backgroundColor: statusColors[status],
          color: status === 'proche péremption' ? '#000' : '#fff'
        }}>
          {status}
        </span>
      ),
      filters: [
        { text: 'Disponible', value: 'disponible' },
        { text: 'Réservé', value: 'réservé' },
        { text: 'Proche péremption', value: 'proche péremption' },
        { text: 'Expiré', value: 'expiré' },
      ],
      onFilter: (value, record) => record.status === value,
    },
    {
      title: 'Localisation',
      dataIndex: 'location',
      key: 'location',
      filters: [
        { text: 'Banque centrale', value: 'Banque centrale' },
        { text: 'Hôpital Principal', value: 'Hôpital Principal' },
        { text: 'Clinique Nord', value: 'Clinique Nord' },
      ],
      onFilter: (value, record) => record.location === value,
    },
    {
      title: 'Date de péremption',
      dataIndex: 'expiryDate',
      key: 'expiryDate',
      render: (date) => dayjs(date).format('DD/MM/YYYY'),
      sorter: (a, b) => dayjs(a.expiryDate).unix() - dayjs(b.expiryDate).unix(),
    },
  ];

  // Gestion de l'export
  const handleExport = () => {
    const csvContent = [
      ['Groupe Sanguin', 'Quantité', 'Statut', 'Localisation', 'Date péremption'],
      ...filteredData.map(item => [
        item.bloodType,
        item.quantity,
        item.status,
        item.location,
        dayjs(item.expiryDate).format('DD/MM/YYYY')
      ])
    ].map(e => e.join(",")).join("\n");

    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement("a");
    link.href = URL.createObjectURL(blob);
    link.download = `stock_sanguin_${dayjs().format('YYYYMMDD')}.csv`;
    link.click();
  };

  return (
    <div className="p-6 bg-gray-50 min-h-screen">
      <div className="mb-6 flex justify-between items-center">
        <h1 className="text-2xl font-bold text-gray-800">Tableau de bord - Stock Sanguin</h1>
        <Button type="primary" icon={<DownloadOutlined />} onClick={handleExport}>
          Exporter les données
        </Button>
      </div>

      {/* Filtres */}
      <div className="bg-white p-4 rounded-lg shadow mb-6">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Groupe sanguin</label>
            <Select
              allowClear
              style={{ width: '100%' }}
              placeholder="Tous les groupes"
              onChange={(value) => setFilters({ ...filters, bloodType: value })}
            >
              <Option value="A+">A+</Option>
              <Option value="A-">A-</Option>
              <Option value="B+">B+</Option>
              <Option value="B-">B-</Option>
              <Option value="AB+">AB+</Option>
              <Option value="AB-">AB-</Option>
              <Option value="O+">O+</Option>
              <Option value="O-">O-</Option>
            </Select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Localisation</label>
            <Select
              allowClear
              style={{ width: '100%' }}
              placeholder="Toutes les localisations"
              onChange={(value) => setFilters({ ...filters, location: value })}
            >
              <Option value="Banque centrale">Banque centrale</Option>
              <Option value="Hôpital Principal">Hôpital Principal</Option>
              <Option value="Clinique Nord">Clinique Nord</Option>
            </Select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Date de péremption</label>
            <RangePicker
              style={{ width: '100%' }}
              onChange={(dates) => setFilters({ ...filters, dateRange: dates })}
            />
          </div>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <div className="bg-white p-4 rounded-lg shadow">
          <h3 className="text-gray-500">Total Poches</h3>
          <p className="text-2xl font-bold">{filteredData.reduce((sum, item) => sum + item.quantity, 0)}</p>
        </div>

        <div className="bg-white p-4 rounded-lg shadow">
          <h3 className="text-gray-500">Disponibles</h3>
          <p className="text-2xl font-bold text-green-600">
            {filteredData.filter(item => item.status === 'disponible').reduce((sum, item) => sum + item.quantity, 0)}
          </p>
        </div>

        <div className="bg-white p-4 rounded-lg shadow">
          <h3 className="text-gray-500">Proche péremption</h3>
          <p className="text-2xl font-bold text-yellow-500">
            {filteredData.filter(item => item.status === 'proche péremption').reduce((sum, item) => sum + item.quantity, 0)}
          </p>
        </div>

        <div className="bg-white p-4 rounded-lg shadow">
          <h3 className="text-gray-500">Expirées</h3>
          <p className="text-2xl font-bold text-red-600">
            {filteredData.filter(item => item.status === 'expiré').reduce((sum, item) => sum + item.quantity, 0)}
          </p>
        </div>
      </div>

      {/* Graphiques */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <div className="bg-white p-4 rounded-lg shadow">
          <h3 className="text-lg font-semibold mb-4">Répartition par groupe sanguin</h3>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={bloodTypeDistribution}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Bar dataKey="value" fill="#8884d8" name="Quantité (pochettes)" />
            </BarChart>
          </ResponsiveContainer>
        </div>

        <div className="bg-white p-4 rounded-lg shadow">
          <h3 className="text-lg font-semibold mb-4">Statut des stocks</h3>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={statusDistribution}
                cx="50%"
                cy="50%"
                labelLine={false}
                outerRadius={80}
                fill="#8884d8"
                dataKey="value"
                nameKey="name"
                label={({ name, percent }) => `${name}: ${(percent * 100).toFixed(0)}%`}
              >
                {statusDistribution.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={statusColors[entry.name]} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Tableau de données */}
      <div className="bg-white p-4 rounded-lg shadow">
        <h3 className="text-lg font-semibold mb-4">Détail des stocks</h3>
        <Table
          columns={columns}
          dataSource={filteredData}
          rowKey="id"
          pagination={{ pageSize: 5 }}
        />
      </div>
    </div>
  );
};

export default BloodStockDashboard;