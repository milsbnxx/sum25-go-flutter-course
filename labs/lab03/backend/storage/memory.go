package storage

import (
	"errors"
	"sync"

	"lab03-backend/models"
)

type MemoryStorage struct {
	mu       sync.RWMutex
	messages map[int]*models.Message
	nextID   int
}

func NewMemoryStorage() *MemoryStorage {
	return &MemoryStorage{
		messages: make(map[int]*models.Message),
		nextID:   1,
	}
}

func (ms *MemoryStorage) GetAll() []*models.Message {
	ms.mu.RLock()
	defer ms.mu.RUnlock()
	list := make([]*models.Message, 0, len(ms.messages))
	for _, msg := range ms.messages {
		list = append(list, msg)
	}
	return list
}

func (ms *MemoryStorage) GetByID(id int) (*models.Message, error) {
	ms.mu.RLock()
	defer ms.mu.RUnlock()
	msg, ok := ms.messages[id]
	if !ok {
		return nil, ErrMessageNotFound
	}
	return msg, nil
}

func (ms *MemoryStorage) Create(username, content string) (*models.Message, error) {
	ms.mu.Lock()
	defer ms.mu.Unlock()
	id := ms.nextID
	msg := models.NewMessage(id, username, content)
	ms.messages[id] = msg
	ms.nextID++
	return msg, nil
}

func (ms *MemoryStorage) Update(id int, content string) (*models.Message, error) {
	ms.mu.Lock()
	defer ms.mu.Unlock()
	msg, ok := ms.messages[id]
	if !ok {
		return nil, ErrMessageNotFound
	}
	msg.Content = content
	return msg, nil
}

func (ms *MemoryStorage) Delete(id int) error {
	ms.mu.Lock()
	defer ms.mu.Unlock()
	if _, ok := ms.messages[id]; !ok {
		return ErrMessageNotFound
	}
	delete(ms.messages, id)
	return nil
}

func (ms *MemoryStorage) Count() int {
	ms.mu.RLock()
	defer ms.mu.RUnlock()
	return len(ms.messages)
}

var (
	ErrMessageNotFound = errors.New("message not found")
	ErrInvalidID       = errors.New("invalid message ID")
)
